#!/bin/bash

SOURCE_LOG=$1
if [ -e /etc/SuSE-release ] ; then
  APACHE_GROUP=www
else
  APACHE_GROUP=apache
fi


updateRepo() {
  BD=$1

  REC=`echo $BD | cut -f6- -d/ | sed s/'\/'/'_'/g`
  echo $REC

  
  if [ ! -f /var/run/$REC.files ] || [ ! -f /var/run/$REC.files.md5 ] ; then
    echo "Creating new files list and md5 sum"
    find $BD -name "*.rpm" | sort > /var/run/$REC.files
    md5sum /var/run/$REC.files > /var/run/$REC.files.md5
    PROCESS=1
  else 
    echo "Comparing existing md5 sum to determine if repo needs updating"
    TMPFILE=`mktemp`
    find $BD -name "*.rpm" | sort > $TMPFILE
    md5sum $TMPFILE > $TMPFILE.md5

    # Overwrite the tmp file with the original so that the MD5 from the tmp file
    # is used to check the original file contents.
    mv $TMPFILE $TMPFILE.orig
    cp /var/run/$REC.files $TMPFILE  
    md5sum -c --status $TMPFILE.md5
    PROCESS=$?
  fi

  # Check if an override was specified as 'Y'
  if [ ! -z $2 ] ; then
    OVERRIDE=`echo $2 | tr [:lower:] [:upper:]`
    if [ $OVERRIDE == "Y" ] ; then
      PROCESS=1
    fi
  fi

  # if the MD5 of both files is not the same, then reprocess everything
  if [ $PROCESS -eq 1 ] ; then
    echo "Refreshing the repodata and recreating the key/signatures"
    mv $TMPFILE.orig /var/run/$REC.files
    md5sum /var/run/$REC.files > /var/run/$REC.files.md5


    #for re in noarch i386 i586 i686 x86_64 SRPMS ; do
      #if [ -d $BD/$re ] ; then
        echo "Creating / updating repository in $BD"
        createrepo --update -o "$BD" "$BD"
        sleep 2

        # This won't work if there are multiple secret eys on a 
        #MY_KEY=$( gpg --list-secret-keys | grep "^sec"|sed -e 's/.*\///;s/ .*//g;'  )
        MY_KEY="084E05B1"
        rm -f $BD/repodata/repomd.xml.asc 
        gpg -a --export "$MY_KEY" > $BD/repodata/repomd.xml.key  
        gpg -a --detach-sign $BD/repodata/repomd.xml
      #fi
    #done 
  fi
  rm -f $TMPFILE $TMPFILE.md5 $TMPFILE.orig > /dev/null
}

updatePermissions() {
  BD=$1

  # Make sure Apache group has write access to the rpm directories
  chgrp $APACHE_GROUP ${BD}/{i386,i586,i686,x86_64,noarch}
  chmod g+w ${BD}/{i386,i586,i686,x86_64,noarch}
}

BASE="/srv/www/htdocs/repos"

if [ -d $BASE ]; then

  OS="suse"
  OSVER="10"
  if [ -d $BASE/$OS/$OSVER ] ; then
    updateRepo $BASE/$OS/$OSVER $1
    updatePermissions $BASE/$OS/$OSVER

  else
    echo "Skipping $BASE/$OS/$OSVER, directory does not exist"
  fi


  OS="suse"
  OSVER="11"
  if [ -d $BASE/$OS/$OSVER ] ; then
    updateRepo $BASE/$OS/$OSVER $1
    updatePermissions $BASE/$OS/$OSVER

  else
    echo "Skipping $BASE/$OS/$OSVER, directory does not exist"
  fi


  OS=el
  OSVER=5
  if [ -d $BASE/$OS/$OSVER ] ; then
    updateRepo $BASE/$OS/$OSVER $1
    updatePermissions $BASE/$OS/$OSVER

  else
    echo "Skipping $BASE/$OS/$OSVER, directory does not exist"
  fi


  OSVER=6
  if [ -d $BASE/$OS/$OSVER ] ; then
    updateRepo $BASE/$OS/$OSVER $1
    updatePermissions $BASE/$OS/$OSVER

  else
    echo "Skipping $BASE/$OS/$OSVER, directory does not exist"
  fi

fi
