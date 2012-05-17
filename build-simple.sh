#!/bin/bash
#
# Copyright 2012, Justin Spies
#   
# Created 2012-02-08 by Justin Spies <justin.spies@atech.com>
#
# Description:
# Builds an RPM package for a simple scripts package to be distributed. Also performs signing of
# the package with GPG per packaging standards. Accepts a single input parameter that is the
# name of the scripts package to be built, except for the leading 'atech-' and trailing '-scripts',
# so to build 'atech-ec2-scripts', use './build-simple.sh ec2'.
#
# Change Log: (Put in order from newest to oldest)
# % MON DD YYYY <name (first + last)> <email@atech.com>
#   - change 1
#   - change 2


# Called as what?
CAS=`basename $0 .sh`
echo $CAS
if [ "$CAS" != "build-simple" ] ; then
  WHAT=$1
  SUFFIX=`echo $CAS | cut -f2 -d-`

  case $SUFFIX in
    scripts)
     PACK=atech-${WHAT}-${SUFFIX}
     SVNPATH="linux/${PACK}"
     ;;
    plugin)
     SVNPATH="monitoring/checks/${WHAT}"
     PACK=atech-${WHAT}-${SUFFIX}
     ;;
    *)
     echo "Unknown build type of $SUFFIX"
     ;;
  esac

  # Version is parameter 1 in this case since the package to build is determined by
  # the filename / symlink name.
  VER=${2:-"nothing"}
else
  if [ -z $1 ] ; then 
    echo "Missing required parameter for the package to build, i.e. 'tivoli', 'c3', 'db2', 'lc'"
    echo "Specify as $0 package [version], i.e. $0 tivoli"
    echo "  note: version is optional"
    exit 1
  fi

  case $1 in
    'db2'|'tivoli'|'c3'|'lc')
      PACK=atech-${1}-scripts
      SVNPATH="linux/${PACK}"
      ;;
    cloudmonitor)
      PACK=atech-$1
      SVNPATH="linux/${PACK}"
      ;;
    nagios-plugins|nsca)
      PACK=$1
      SVNPATH="monitoring/${PACK}"
      ;;
    *)
      PACK=$1
      SVNPATH="linux/${PACK}"
      ;;
  esac

  # Version is parameter 2 in this case since the package to build is a passed in parameter
  VER=${2:-"nothing"}
fi
echo "Building for $PACK"



if [ "$VER" == "nothing" ] ; then
  if [ -f ~/packages/SPECS/${PACK}.spec ] ; then
    VERSION=`grep "^%define version " ~/packages/SPECS/${PACK}.spec | awk '{print $3}'`
    if [ "x${VERSION}x" == "xx" ] ; then 
      echo "Could not determine version from spec file, assuming 'trunk'"
      VERSION=trunk
      VERPATH="trunk/"
    else
      VERPATH="tags/${VERSION}/"
    fi
  else
    echo "Version not specified and no spec file available, assuming 'trunk'"
    VERSION=trunk
    VERPATH="trunk/"
  fi
else
  # Work with specific version per command line
  VERSION=$VER
  if [ "$VER" == "trunk" ] ; then
    VERPATH="trunk/"
  else
    VERPATH="tags/${VERSION}/"
  fi
fi



# Checkout the code if it doesn't exist.
if [ ! -d ${PACK}-${VERSION} ] ; then
  echo "Source directory ${PACK}-${VERSION} does not exist, will check out ${SVNPATH}/${VERPATH} from SVN as version ${VERSION}"
  svn co https://source.atech.com/svn/ManagedServices/${SVNPATH}/${VERPATH} ./${PACK}-${VERSION}

  if [ $? -ne 0 ] ; then
    echo "Could not checkout code tagged as version ${VERSION}, has the tag been created?"
    exit 3
  fi
fi

if [ -f ./${PACK}-${VERSION}/${PACK}.spec ] ; then
  cp ./${PACK}-${VERSION}/${PACK}.spec ./SPECS/${PACK}-${VERSION}.spec
fi

# One last check since a) the code may have just been checked out; and b) there may be a missing SPEC file.
if [ ! -f ./SPECS/${PACK}-${VERSION}.spec ] ; then
  echo "No spec file exists, cannot continue build"
  exit 4
fi


# If the trunk was checked out, then the directory needs to be moved to match the version number in 
# the spec file so that the .tgz sources file is correctly named and the package builds.
if [ $VERSION == "trunk" ] ; then
  VERSION=`grep "^%define version " ~/packages/SPECS/${PACK}-trunk.spec | awk '{print $3}'`

  if [ "x${VERSION}x" == "xx" ] ; then
    echo "Could not determine version from spec file, cannot continue"
    exit 6
  fi

  #if [ -h ~/packages/${PACK}-${VERSION} ] ; then
  #  rm -f ~/packages/${PACK}-${VERSION}
  #fi
  #ln -s ${PACK}-trunk ${PACK}-${VERSION}
  rm -rf ${PACK}-${VERSION}
  mv ${PACK}-trunk ${PACK}-${VERSION}

  rm -f ~/packages/SPECS/${PACK}-${VERSION}.spec
  mv ~/packages/SPECS/${PACK}-trunk.spec ~/packages/SPECS/${PACK}-${VERSION}.spec
fi

rm -f ~/packages/SPECS/${PACK}.spec
ln -s ~/packages/SPECS/${PACK}-${VERSION}.spec ~/packages/SPECS/${PACK}.spec


# Note: 'VERSION' is not a typo, see above
echo Building version $VERSION
cd ~/packages


if [ -x ${PACK}-${VERSION}/build-sources.sh ] ; then
  echo "Building source archive using custom script" 
 
  BUILDDIR=`pwd` 
  SOURCEFILE=`${PACK}-${VERSION}/build-sources.sh $BUILDDIR $PACK $VERSION | awk '{print $2}'`
  if [ ! -f $SOURCEFILE ] ; then
    echo "Sources file failed to archive, packaging failed"
    exit 5
  fi
else
  echo "Building standard source archive" 
  find ${PACK}-${VERSION}/ | grep -v ".svn" > ${PACK}-files.txt 
  tar czvf SOURCES/${PACK}-${VERSION}.tgz --exclude=patches --exclude=.svn --exclude=*.spec -T ${PACK}-files.txt > /dev/null
fi

if [ $? -ne 0 ] ; then
  echo "Could not build ${PACK} tar file"
  exit 1
fi

rm -f ${PACK}*.txt


# Move any patch files needed by the build process into the SOURCES directory from where they will be pulled.
if [ -d ${PACK}-${VERSION}/patches ] ; then
  mv ${PACK}-${VERSION}/patches/* ./SOURCES/
fi


cd ~/packages/SPECS

echo "Building RPMs now, see /tmp/rpmbuild-${PACK}-$VERSION.err and /tmp/rpmbuild-${PACK}-$VERSION.log for details"
rpmbuild -ba ${PACK}-${VERSION}.spec 2>/tmp/rpmbuild-${PACK}-$VERSION.err >/tmp/rpmbuild-${PACK}-$VERSION.log


if [ $? -eq 0 ] ; then
  echo "Adding GPG signatures"
  for file in `grep ^Wrote /tmp/rpmbuild-${PACK}-$VERSION.log | awk '{print $2}'` ; do
    echo "Adding signature to $file"
    rpm --addsign $file
  done

  echo "Initiating package updates"
  ~/packages/update-repos.sh /tmp/rpmbuild-${PACK}-$VERSION.log

else
  echo "Build errors encountered, see /tmp/rpmbuild-${PACK}-$VERSION.err for full details, showing last 20 lines below:"
  tail -20 /tmp/rpmbuild-${PACK}-$VERSION.err
fi
