#!/bin/bash


. /u01/oracle/.bash_profile


rm -f /u01/app/oracle/p4547809-install.rsp
wget http://xenhost/syssetup/shared/9i/p4547809-install.rsp -O /u01/app/oracle/p4547809-install.rsp


export DISPLAY=127.0.0.1:1
cd /u01/software/oracle/patches/Disk1
./runInstaller -silent -responseFile /u01/app/oracle/p4547809-install.rsp

