#!/bin/bash
#
# Script used to initiate the installation of Oracle 9i in an automated fashion.  This script
# is typically called by another script, often the oracle-setup script that is copied to a
# server before the OS installation finishes and is then run when the server first starts.  
# This script must be run as the 'oracle' user account, either through the use of the
# 'su' command (with the '-c' option) or through the 'sh' command.


. /u01/oracle/.bash_profile

rm -f /u01/app/oracle/install.rsp
wget http://xenhost/syssetup/shared/9i/install.rsp -O /u01/app/oracle/testdb-install.rsp

export DISPLAY=127.0.0.1:1
cd /u01/software/oracle/Disk1
./runInstaller -silent -responseFile /u01/app/oracle/testdb-install.rsp
