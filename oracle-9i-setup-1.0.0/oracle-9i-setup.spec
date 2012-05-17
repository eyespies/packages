# Specfile for <type purpose>
# Created YYYY-MM-DD by Justin Spies <justin@thespies.org>
#
# Copyright 2012, Justin Spies
#
# For file history, see notes at the end of this file.

# Default to RedHat _crondir
%define _crondir %{_var}/spool/cron

%if %is_centos
%define dist centos
%endif

%if %is_suse
  %if %is_opensuse
    # Used simply to determine the correct version
    %define dist openSUSE

    # Used if wanting a different tag for SLES vs. OpenSUSE
    #%define disttag osl
  %else
    %define dist sles
  %endif

# Use the same tag for SLES / OpenSuSE
%define disttag sles

%define _crondir %{_var}/spool/cron/tabs
%endif


%if %is_fedora
%define dist fedora
%define disttag fc
%endif


%define name oracle-9i-setup
%define version 1.0.0
%define release 0.10_%disttag%distver


#--------------------------------------------------------------------------------
# Example of conditional macro definitions
#--------------------------------------------------------------------------------
# Default values are --without-ldap --with-ssl.
#
# Read: If neither macro exists, then add the default definition.
#%{!?_with_ldap: %{!?_without_ldap: %define _without_ldap --without-ldap}}
#%{!?_with_ssl: %{!?_without_ssl: %define _with_ssl --with-ssl}}

# Performance data handling method to use. By default we will use
# the file-based one (as existed in NetSaint).
# You can select the external command based method (the defaut for
# Nagios) by specifying
# --define 'PERF_EXTERNAL 1'
# in the rpm command-line
#%{!?PERF_EXTERNAL:           %define         PERF_EXTERNAL 0}
#--------------------------------------------------------------------------------


#--------------------------------------------------------------------------------
# Package information, most of this is defined above
#--------------------------------------------------------------------------------
Summary: Set of scripts for automating the provisioning of EC2 instances
Name: %{name}
Version: %{version}
Vendor: Claret Technology
Release: %{release}
License: Proprietary
Group: Application/System
Source: %{name}-%{version}.tgz
BuildArch: noarch
BuildRoot: %{_tmppath}/%{name}-buildroot
Prefix: %{_prefix}
Prefix: /etc

# What other packages are required by this package at runtime? Include a comma separated list with optional version qualifiers.
#Requires: gd > 1.8, zlib, libpng, libjpeg, bash, grep

# What other packages are required by this package in order to actually build and package the files?
#BuildRequires: gd-devel > 1.8, zlib-devel, libpng-devel, libjpeg-devel
#--------------------------------------------------------------------------------


#--------------------------------------------------------------------------------
# Long description of the package.
#--------------------------------------------------------------------------------
%description

#--------------------------------------------------------------------------------


#--------------------------------------------------------------------------------
# This section defines the steps to complete before building and packaging the 
# software. These steps are performed at package build time, not at package
# install time.
#--------------------------------------------------------------------------------
%prep
%setup -q

# the 'set +e' disables checking of the return code for the grep command. without this directive,
# if the user does not exist, then RPM will throw an error. It is only needed in the %pre script.
set +e
grep oinstall /etc/group > /dev/null
if [ $? -eq 1 ] ; then
  groupadd -g 1000 oinstall
  groupadd -g 1001 dba
  groupadd -g 1002 dbo
fi
set -e

set +e
grep oracle /etc/passwd > /dev/null
if [ $? -eq 1 ] ; then
  mkdir /u01
  useradd -c "Oracle Product Owner" -g oinstall -G dba,dbo -m -d /u01/oracle oracle
fi
set -e

exit 0
#--------------------------------------------------------------------------------


#--------------------------------------------------------------------------------
# Specify the steps required before performing the installation on a target 
# system. This may include creating a user account or updating a system 
# parameter. It should not include creation of files or directories as that is 
# the responsibility of the %files section.
#--------------------------------------------------------------------------------
%pre
exit 0

#--------------------------------------------------------------------------------


#--------------------------------------------------------------------------------
# Defines the steps to be performed after the files are copied. This is where 
# most of the work will be performed in many RPM packages. An example for a DB2
# package is included below.
#--------------------------------------------------------------------------------
%post

# Make sure that the service starts on reboot
chkconfig oracle-setup on

# the 'set +e' disables checking of the return code for the grep command. without this directive,
# if the user does not exist, then RPM will throw an error. It is only needed in the %pre script.
#set +e
#set -e
# Check for an existing cron job, if none exists, add one.
#if [ -f %{_crondir}/root ] ; then
  # re-enable cron jobs if they exist, they will be ignored below with the grep commands
  #sed -i s,"^#\(\*\/[0-9]\{1\,2\} \* \* \* \* /sbin/script-name.sh.*\)","\1",g %{_crondir}/root 

  #grep -e "^\*/[0-9]\{1,2\} \* \* \* \* /sbin/script-name.sh" %{_crondir}/root > /dev/null
  #if [ $? -eq 1 ] ; then
  #  echo "*/5 * * * * /sbin/script-name.sh > /dev/null" >> %{_crondir}/root
  #fi

  #grep -e "^\*/[0-9]\{1,2\} \* \* \* \* /sbin/script-name.sh" %{_crondir}/root > /dev/null
  #if [ $? -eq 1 ] ; then
  #  echo "*/10 * * * * /sbin/script-name.sh > /dev/null" >> %{_crondir}/root
  #fi
#else
  #echo "*/5 * * * * /sbin/script-name.sh > /dev/null" >> %{_crondir}/root
  #echo "*/10 * * * * /sbin/script-name.sh > /dev/null" >> %{_crondir}/root
#fi

exit 0

#--------------------------------------------------------------------------------


#--------------------------------------------------------------------------------
# This section contains the commands to be executed before the package is removed
# from a system. This section is not often used.
#--------------------------------------------------------------------------------
%preun
exit 0

#--------------------------------------------------------------------------------


#--------------------------------------------------------------------------------
# Defines commands that are executed after the package is removed from a system.
# This may include commands to remove user accounts (keep in mind the impact this
# will have as files will no longer have a user account association), removing
# system customizations, etc.
# 
# The folowing example shos removing the db2 instance when a package is removed.
#--------------------------------------------------------------------------------
%postun
# This won't execute for -ivh, but will for -Uvh and -e
case $1 in
  # Performing an uninstall and not an update (i.e., '-e')
  0)
    # Using ',' instead of '/' because _bindir has '/' chars that would need escaping.
    #sed -i s,"^\*\/[0-9]\{1\,2\} \* \* \* \* /sbin/script-name.sh","#&",g %{_crondir}/root 
    ;;
  # Performing an update (i.e., '-Uvh')
  1)
    # Not doing anything for updates, leave CRON alone.
    ;;
esac
exit 0

#--------------------------------------------------------------------------------


#--------------------------------------------------------------------------------
# This shows the defintion of a pre installation command set for the 'scripts'
# sub-package. There should be one of these for each sub-package that is created
# by this spec file.
#--------------------------------------------------------------------------------
#%pre scripts
#exit 0

#--------------------------------------------------------------------------------


#--------------------------------------------------------------------------------
# This shows the defintion of a post installation command set for the 'scripts'
# sub-package. There should be one of these for each sub-package that is created
# by this spec file.
#--------------------------------------------------------------------------------
#%post scripts
#exit 0

#--------------------------------------------------------------------------------


#--------------------------------------------------------------------------------
# This shows the defintion of a pre-uninstallation command set for the 'scripts'
# sub-package. There should be one of these for each sub-package that is created
# by this spec file.
#--------------------------------------------------------------------------------
#%preun scripts
#exit 0

#--------------------------------------------------------------------------------


#--------------------------------------------------------------------------------
# This shows the defintion of a post-uninstallation command set for the 'scripts'
# sub-package. There should be one of these for each sub-package that is created
# by this spec file.
#--------------------------------------------------------------------------------
#%postun scripts
#exit 0 

#--------------------------------------------------------------------------------


#--------------------------------------------------------------------------------
# Define the actual installation process for the files during the package build.
# There are a number of variables/macros available, see http://www.rpm.org for
# details. Note that the 'install' command can only install individual directories
# and files, so it is often easier to set permissions on files as a group and
# use the rsync command to move the files from the source folder to the build
# root.
# 
# In most cases, this section seems pointless as it is just copying files from
# one place to another for packaging. It is important to keep in mind, however,
# that there are many compiled software packages and this section is used to
# install / configure files from the resulting build process, in which case
# this section will include more than simple copy commands.
#--------------------------------------------------------------------------------
%install
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT
install -m 0775 -o oracle -g dba -d ${RPM_BUILD_ROOT}/u01
install -m 0775 -o oracle -g dba -d ${RPM_BUILD_ROOT}/u01/oracle
install -m 0775 -o oracle -g dba -d ${RPM_BUILD_ROOT}/u01/oracle/setup
install -m 0775 -o root -g root -d ${RPM_BUILD_ROOT}%{_sysconfdir}/init.d
install -m 0755 -o oracle -g dba u01/oracle/setup/oracle-install.sh ${RPM_BUILD_ROOT}/u01/oracle/setup/
install -m 0755 -o oracle -g dba u01/oracle/setup/oracle-patch.sh ${RPM_BUILD_ROOT}/u01/oracle/setup/
install -m 0755 -o oracle -g dba u01/oracle/setup/orainstRoot.sh ${RPM_BUILD_ROOT}/u01/oracle/setup/
install -m 0644 -o oracle -g dba u01/oracle/setup/install.rsp ${RPM_BUILD_ROOT}/u01/oracle/setup/
install -m 0644 -o oracle -g dba u01/oracle/setup/p4547809-install.rsp ${RPM_BUILD_ROOT}/u01/oracle/setup/
install -m 0755 -o root -g root etc/init.d/oracle-setup ${RPM_BUILD_ROOT}/etc/init.d/

#--------------------------------------------------------------------------------


#--------------------------------------------------------------------------------
# Cleanup after the package has been created. In most cases the following will
# suffice.
#--------------------------------------------------------------------------------
%clean
rm -rf $RPM_BUILD_ROOT

#--------------------------------------------------------------------------------


#--------------------------------------------------------------------------------
# A list of files to be copied. This is necessary because there is no easy way
# for RPM to determine which files to install and where in an automated fashion
# for complicated packages. Script packages are often simple and this section 
# seems somewhat overdone, however as packages increase in complexity, this
# section becomes more useful.
#
# Keep in mind that when the package is built, the package system acts as if
# though a 'chroot $RPM_BUILD_ROOT' has been performd.
#--------------------------------------------------------------------------------
%files 
%defattr(0755,root,root)
/u01/oracle/setup/oracle-install.sh
/u01/oracle/setup/oracle-patch.sh
/u01/oracle/setup/orainstRoot.sh
%{_sysconfdir}/init.d/oracle-setup

%defattr(0644,root,root)
/u01/oracle/setup/install.rsp
/u01/oracle/setup/p4547809-install.rsp

#%config(noreplace) /etc/sysconfig/myconfig

#--------------------------------------------------------------------------------


#--------------------------------------------------------------------------------
# Change log for the package, please make sure to record all changes here in the
# format shown. Keep the newest entries at the top and make sure to include your
# name and email address.
#--------------------------------------------------------------------------------
%changelog
* Mon Jan 01 2012 Justin Spies <justin@thespies.org>
- version 1.0.0 release 0.10
- Initial version for testing installation of the package.
