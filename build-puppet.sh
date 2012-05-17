#!/bin/bash
#
# Copyright 2012, Justin Spies
#   
# Created 2012-02-08 by Justin Spies <justin.spies@atech.com>
#
# Description:
# Builds the Puppet software package RPMs for distribution, including signing of the 
# packages.
#
# Change Log: (Put in order from newest to oldest)
# % MON DD YYYY <name (first + last)> <email@atech.com>
#   - change 1
#   - change 2


if [ -e /etc/redhat-release ] || [ -e /etc/centos-release ] ; then
  DIST=redhat
else
  if [ -e /etc/SuSE-release ] || [ -e /etc/openSuSE-release ] ; then
    DIST=suse
  else
    echo "Unrecognized distribution, quitting"
    exit 3
  fi
fi

PACK=atech-puppet-${DIST}
echo "Building for $PACK"
if [ ! -f ~/packages/SPECS/${PACK}.spec ] ; then 
  echo "The spec file ~/packages/SPECS/${PACK}.spec does not exist!"
  exit 2
fi


VERSION=`grep "^%define version " ~/packages/SPECS/${PACK}.spec | awk '{print $3}'`



# Note: 'VERSION' is not a typo, see above
if [ "x${VERSION}x" == "xx" ] ; then
  echo "Could not determine version from spec file, quitting"
  exit 1
fi



# Note: 'VERSION' is not a typo, see above
echo Building version $VERSION
cd ~/packages

# Puppet sources are stored in SOURCES/ as a tar.gz file that is included in the packaging directory when checked out
#if [ ! -d ${PACK}-${VERSION} ] ; then
#  echo "Source directory ${PACK}-${VERSION} does not exist, will check out trunk from SVN as version ${VERSION}"
#  svn co https://source.atech.com/svn/ManagedServices/linux/${PACK}/trunk/ ./${PACK}-${VERSION}
#fi

#find ${PACK}-${VERSION}/ | grep -v ".svn" > ${PACK}-files.txt 

#tar czvf SOURCES/${PACK}-${VERSION}.tgz --exclude=.svn -T ${PACK}-files.txt > /dev/null
#if [ $? -ne 0 ] ; then
#  echo "Could not build ${PACK} tar file"
#  exit 1
#fi

#rm -f ${PACK}*.txt

cd ~/packages/SPECS

echo "Building RPMs now, see /tmp/rpmbuild-${PACK}-$VERSION.err and /tmp/rpmbuild-${PACK}-$VERSION.log for details"
rpmbuild -ba ${PACK}.spec 2>/tmp/rpmbuild-${PACK}-$VERSION.err >/tmp/rpmbuild-${PACK}-$VERSION.log


if [ $? -eq 0 ] ; then
  echo "Adding GPG signatures"
  for file in `grep ^Wrote /tmp/rpmbuild-${PACK}-$VERSION.log | awk '{print $2}'` ; do
    echo "Adding signature to $file"
    rpm --addsign $file
  done

  ~/packages/update-repos.sh

else
  echo "Build errors encountered, see /tmp/rpmbuild-${PACK}-$VERSION.err for full details, showing last 20 lines below:"
  tail -20 /tmp/rpmbuild-${PACK}-$VERSION.err
fi
