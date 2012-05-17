#!/bin/bash


cd SPECS

for s in *-scripts.spec ; do 
  VER=`grep "define version" $s | awk '{print $3}'` 
  BASE=`basename $s .spec` 
  DN=$BASE-$VER
  svn co https://source.atech.com/svn/ManagedServices/linux/$BASE/trunk/ ./$DN 
  tar czvf ../SOURCES/$DN.tgz $DN --exclude=.svn
  rm -rf $DN
done

cd ..
