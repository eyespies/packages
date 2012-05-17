#!/bin/bash

SOURCE_LOG=$1
DIR=`dirname $0`

updateRepo() {
  BD=$1
#  for re in noarch i386 i586 i686 x86_64 SRPMS ; do
#    if [ -d $BD/$re ] ; then
    if [ -d $BD ] ; then
      echo "Creating / updating repository in $BD"
      createrepo --update -o "$BD" "$BD"
    fi
#  done 
}


BASE="/srv/www/htdocs/repos"

echo "Checking for distribution type"
if [ -e /etc/redhat-release ] || [ -e /etc/centos-release ] ; then
  DIST=redhat
  grep -i centos /etc/redhat-release > /dev/null
  if  [ $? -eq 0 ] ; then 
    DIST=centos
  fi
 
else
  if [ -e /etc/SuSE-release ] || [ -e /etc/openSuSE-release ] ; then
    DIST=sles
  else
    echo "Unrecognized distribution, quitting"
    exit 3
  fi
fi

echo "Found distribution $DIST now getting the version"
DISTVER=`rpm -q --queryformat='%{VERSION}' ${DIST}-release | cut -f1 -d. | sed s/://g | sed s/Server//g` 
echo "Using distribution version $DISTVER"


if [ -d $BASE ]; then

  OS="suse"
  OSVER="10"
  if [ -d $BASE/$OS/$OSVER ] && [ "$DISTVER" == "$OSVER" ]; then
    echo "Copying files to $BASE/$OS/$OSVER"
    rsync -avr ~/packages/RPMS/* $BASE/$OS/$OSVER/ --exclude=*sles11*.rpm --exclude=*el5*.rpm --exclude=*el6*.rpm --exclude=.svn >/dev/null

    #updateRepo $BASE/$OS/$OSVER
  else
    echo "Skipping $BASE/$OS/$OSVER, directory does not exist"
  fi


  OS="suse"
  OSVER="11"
  if [ -d $BASE/$OS/$OSVER ] && [ "$DISTVER" == "$OSVER" ]; then
    echo "Copying files to $BASE/$OS/$OSVER"
    rsync -avr ~/packages/RPMS/* $BASE/$OS/$OSVER/ --exclude=*sles10*.rpm --exclude=*el5*.rpm --exclude=*el6*.rpm --exclude=.svn >/dev/null

    #updateRepo $BASE/$OS/$OSVER
  else
    echo "Skipping $BASE/$OS/$OSVER, directory does not exist"
  fi


  OS=el
  OSVER=5
  if [ -d $BASE/$OS/$OSVER ] && [ "$DISTVER" == "$OSVER" ]; then
    echo "Copying files to $BASE/$OS/$OSVER"
    rsync -avr ~/packages/RPMS/* $BASE/$OS/$OSVER/ --exclude=*sles10*.rpm --exclude=*sles11*.rpm --exclude=*el6*.rpm --exclude=.svn >/dev/null

    #updateRepo $BASE/$OS/$OSVER
  else
    echo "Skipping $BASE/$OS/$OSVER, directory does not exist"
  fi


  OSVER=6
  if [ -d $BASE/$OS/$OSVER ] && [ "$DISTVER" == "$OSVER" ]; then
    echo "Copying files to $BASE/$OS/$OSVER"
    rsync -avr ~/packages/RPMS/* $BASE/$OS/$OSVER/ --exclude=*sles10*.rpm --exclude=*sles11*.rpm --exclude=*el5*.rpm --exclude=.svn >/dev/null

    #updateRepo $BASE/$OS/$OSVER
  else
    echo "Skipping $BASE/$OS/$OSVER, directory does not exist"
  fi

  $DIR/refresh-repodata.sh

else
  # If building on SuSE system, then push the packages up to
  # the SuSE package repo.
  if [ -e /etc/SuSE-release ] ; then
    URL="http://suse.atecheb.com/util/up-atech-pack.php"
  else
    URL="http://confluence.atech.com/util/up-atech-pack.php"
  fi

  read -s -p "Please enter the upload password: " URL_PASS
  echo ""

  # TODO Upload all files at once, but will require updating the PHP upload script
  echo "Uploading files to repo server"
  for file in `grep ^Wrote $SOURCE_LOG | awk '{print $2}'` ; do
    curl -u buildsys:${URL_PASS} -F file=@${file} $URL 
  done
fi
