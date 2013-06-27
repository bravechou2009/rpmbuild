#!/bin/bash
##############################################

## Environment Setup
#-------------------
CL_PARAMS=$#
CONFDIR=/usr/share/tomcat6/webapps/conf
#-------------------

usage()
{
   echo
   echo "USAGE:  install.sh <env>"
   echo
   exit 99;
}

case $CL_PARAMS in
   1) ENV=$1
      ;;
   *) usage
      ;;
esac

if [ -d $CONFDIR/$ENV ]; then
   for file in `ls $CONFDIR/$ENV`
   do
      echo $file
      newfile=`echo $file | sed -e 's/.$ENV//'`
      echo $newfile
   done
else
   echo "$CONFDIR/$ENV does not exist!"
   exit 2
fi
