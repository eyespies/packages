#!/bin/sh
INVPTR=/etc/oraInst.loc
INVLOC=/u01/app/oracle/oraInventory
GRP=oinstall
PTRDIR="`dirname $INVPTR`";
# Create the Software Inventory location pointer file
if [ ! -d "$PTRDIR" ]; then
 mkdir -p $PTRDIR;
fi
echo "Creating Oracle Inventory pointer file ($INVPTR)";
echo    inventory_loc=$INVLOC > $INVPTR
echo    inst_group=$GRP >> $INVPTR
chmod 644 $INVPTR
# Create the Inventory Directory if it doesn't exist
if [ ! -d "$INVLOC" ];then
 echo "Creating the Oracle Inventory Directory ($INVLOC)";
 mkdir -p $INVLOC;
 chmod 775 $INVLOC;
fi
echo "Changing groupname of $INVLOC to oinstall.";
chgrp oinstall $INVLOC;
if [ $? != 0 ]; then
 echo "WARNING: chgrp of $INVLOC to oinstall failed!";
fi
