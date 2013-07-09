#!/bin/bash
##############################################

## Environment Setup
#-------------------
CL_PARAMS=$#
##TEST##BLD_CONFDIR=/home/e482fh/ipclab-test/usr/share/tomcat6/webapps/conf
##TEST##DEST_CONFDIR=/home/e482fh/ipclab-test/etc/tomcat6
BLD_CONFDIR=/usr/share/tomcat6/webapps/conf
DEST_CONFDIR=/etc/tomcat6
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

if [ -d $BLD_CONFDIR/$ENV ]; then
   fc=`find $BLD_CONFDIR/$ENV -type f -print 2>/dev/null | wc -l`

   if [ $fc -gt 0 ]; then
      for file in `find $BLD_CONFDIR/$ENV -type f -print 2>/dev/null`
      do
#         echo cp $file $DEST_CONFDIR/.
         cp $file $DEST_CONFDIR/.

         if [ $? -eq 0 ]; then
            echo "Successfully copied file $file"
         else
            echo "ERROR: Problem copying $file"
         fi
      done
   else
      echo "No files found in $BLD_CONFDIR/$ENV"
   fi
else
   echo "$BLD_CONFDIR/$ENV does not exist!  Please verify environment and rerun."
   exit 2
fi
