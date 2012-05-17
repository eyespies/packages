#!/bin/bash


CONFIG_FILE=/etc/sysconfig/orafailover

if [ ! -f $CONFIG_FILE ] ; then
  exit 1
fi

. $CONFIG_FILE


cd $BASEDIR

#  Unmount NFS shares if this is the real standby starting the primary DB
grep linuxdb /etc/fstab > /dev/null
if [ $? -eq 0 ] ; then
   for s in `grep linuxdb /etc/fstab | awk '{print $2}'` ; do
      if [ "$s" != "/mnt/up2date" ] ; then
         umount $s
      fi
   done 
fi


#  Shutdown the Oracle databases, they won't be accessible.
service oracle stop

#  Shutdown the Oracle listeners, they'll stop responding as soon
#  as the interface goes down.
service oralsnr stop


#  Shutdown the secondary interface address over which all
#  Oracle services are running.
ifdown ${STANDBY_IFNAME}

# Update network config with the IP of the primary server.
TMPFILE=`mktemp`
grep -v IPADDR /etc/sysconfig/ifcfg-${STANDBY_IFNAME} > $TMPFILE
echo "IPADDR=${STANDBY_IP}" >> $TMPFILE
mv $TMPFILE /etc/sysconfig/ifcfg-${STANDBY_IFNAME}


echo "Run the set-primary script on the other server and press any key when finished"
# Need to test this, especially the return code.
# ssh root@${ALT_HOST} -c `/root/bin/set-primary.sh`

#  The -t is a ten second timeout.
#read -n1 -t10 any_key
read -n1 any_key


#  Restart the interface using the standby address.
ifup ${STANDBY_IFNAME}

# Turn off all DBs
disableAllOraEntries $ORATAB

# Update the Oracle DBs to be started.
enableOraEntries $ORATAB "$STANDBY_DBS"


# Turn off all listeners
disableAllOraEntries $ORALSNR

# Turn on selected listeners
enableOraEntries $ORALSNR "$STANDBY_LSNRS"



#  Restart the Oracle listeners.
service oralsnr start

#  Restart the Oracle databases, in this case only VMFG and VQ.
service oracle-standby start


#  Mount NFS shares if this is the real primary starting the standby DB
grep dbtest /etc/fstab > /dev/null
if [ $? -eq 0 ] ; then
   for s in `grep dbtest /etc/fstab | awk '{print $2}'` ; do
     mount $s
   done 
fi
