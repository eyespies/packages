#!/bin/bash


. ./orafuncs

CONFIG_FILE=/etc/sysconfig/orafailover

if [ ! -f $CONFIG_FILE ] ; then
  exit 1
fi

. $CONFIG_FILE


cd $BASEDIR


#  Unmount NFS shares if this is the real primary starting the standby DB
grep dbtest /etc/fstab > /dev/null
if [ $? -eq 0 ] ; then
   for s in `grep dbtest /etc/fstab | awk '{print $2}'` ; do
     umount $s
   done
fi

#  Shutdown the Oracle databases, they won't be accessible.
service oracle-standby stop

#  Shutdown the Oracle listeners, they'll stop responding as soon
#  as the interface goes down.
service oralsnr stop


#  Shutdown the secondary interface address over which all
#  Oracle services are running.
ifdown ${PRIMARY_IFNAME}
#rsync -avr primary/* / > /dev/null

# Update network config with the IP of the primary server.
TMPFILE=`mktemp`
grep -v IPADDR /etc/sysconfig/ifcfg-${PRIMARY_IFNAME} > $TMPFILE
echo "IPADDR=${PRIMARY_IP}" >> $TMPFILE
mv $TMPFILE /etc/sysconfig/ifcfg-${PRIMARY_IFNAME}


#  Restart the interface using the standby address.
ifup ${PRIMARY_IFNAME}

# Turn off all DBs
disableAllOraEntries $ORATAB

# Update the Oracle DBs to be started.
enableOraEntries $ORATAB "$PRIMARY_DBS"


# Turn off all listeners
disableAllOraEntries $ORALSNR

# Turn on selected listeners
enableOraEntries $ORALSNR "$PRIMARY_LSNRS"


#  Restart the Oracle listeners.
service oralsnr start

#  Restart the Oracle databases, in this case only VMFG and VQ.
service oracle start


#  Mount NFS shares if this is the real standby starting the standby DB
grep linuxdb /etc/fstab > /dev/null
if [ $? -eq 0 ] ; then
   for s in `grep linuxdb /etc/fstab | awk '{print $2}'` ; do
     if [ "$s" != "/mnt/up2date" ] ; then
       mount $s
     fi
   done
fi
