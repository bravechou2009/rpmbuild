#!/bin/sh
set -x

PACKAGE_NAME=${PACKAGE_NAME:-''}
PACKAGE_SUMMARY=${PACKAGE_NAME:-''}
PACKAGE_VERSION=${PACKAGE_VERSION:-''}
PACKAGE_RELEASE=${PACKAGE_RELEASE:-0}
PACKAGE_GROUP=${PACKAGE_GROUP:-"Applications/System"}
PACKAGE_LICENSE=${PACKAGE_LICENSE:-"Copyright $(date +'%Y') Enterprise Holdings, Inc."}
PACKAGE_ARCH=${PACKAGE_ARCH:-"noarch"}
PACKAGE_DESCRIPTION=${PACKAGE_DESCRIPTION:-""}
PACKAGE_WAR_FILES=${PACKAGE_WAR_FILES:-""}

STARTING_DIRECTORY=$(pwd)

help()
{
	cat << EOF
------------------------------------------
$0 - Create an RPM package for a Tomcat application

-n or PACKAGE_NAME : Name of package
-s or PACKAGE_SUMMARY : Summary string
-v or PACKAGE_VERSION : Version
-r or PACKAGE_RELEASE : Release string
-g or PACKAGE_GROUP : Package group
-l or PACKAGE_LICENSE : License/Copyright
-d or PACKAGE_DESCRIPTION : Description
-W or PACKAGE_WAR_FILES : Directory containing war files
-h : This help text
------------------------------------------
EOF
}

while getopts n:s:v:r:g:l:W:d:h option
do
	case $option in
		n) PACKAGE_NAME=$OPTARG
		   ;;
		s) PACKAGE_SUMMARY=$OPTARG
		   ;;
		v) PACKAGE_VERSION=$OPTARG
		   ;;
		r) PACKAGE_RELEASE=$OPTARG
		   ;;
		g) PACKAGE_GROUP=$OPTARG
		   ;;
		l) PACKAGE_LICENSE=$OPTARG
		   ;;
		W) PACKAGE_WAR_FILES=$OPTARG
		   ;;
		h) help
		   exit 1
		   ;;
	esac
done
shift $((OPTIND - 1))

if [ -z "$PACKAGE_NAME" ]
then
	echo "Error - No package name given"
	help
	exit 2
fi

if [ -z "$PACKAGE_SUMMARY" ]
then
	echo "Error - No package summary given"
	help
	exit 2
fi

if [ -z "$PACKAGE_VERSION" ]
then
	echo "Error - No package version given"
	help
	exit 2
fi

if [ -z "$PACKAGE_DESCRIPTION" ]
then
	PACKAGE_DESCRIPTION="${PACKAGE_NAME} - ${PACKAGE_SUMMARY}"
fi

if [ ! -d "$PACKAGE_WAR_FILES" ]
then
	echo "Error - <${PACKAGE_WAR_FILES}> is not a directory."
	help
	exit 2
fi

ls -l ${PACKAGE_WAR_FILES}/*.war
if [ $? -ne 0 ]
then
	echo "Error - No .war files in $PACKAGE_WAR_FILES directory."
	help
	exit 2
fi

mkdir -p ${PACKAGE_NAME}/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
SPECFILE="${PACKAGE_NAME}/SPECS/${PACKAGE_NAME}.spec"

(
m4 -D package_name="${PACKAGE_NAME}" \
   -D package_summary="${PACKAGE_SUMMARY}" \
   -D package_version="${PACKAGE_VERSION}" \
   -D package_release="${PACKAGE_RELEASE}" \
   -D package_group="${PACKAGE_GROUP}" \
   -D package_license="${PACKAGE_LICENSE}" \
   -D package_arch="${PACKAGE_ARCH}" \
   -D package_description="${PACKAGE_DESCRIPTION}" \
   << EOSpec
Name            : package_name
Summary         : package_summary
Version         : package_version
Release         : package_release

##Group           : Applications/File
Group           : package_group
License         : package_license

#BuildArch       : noarch
BuildArch       : package_arch
BuildRoot       : %{_tmppath}/%{name}-%{version}-root


# Use "Requires" for any dependencies, for example:
# Requires        : tomcat6

# Description gives information about the rpm package. This can be expanded up to multiple lines.
%description
package_description


# Prep is used to set up the environment for building the rpm package
# Expansion of source tar balls are done in this section
%prep

# Used to compile and to build the source
%build

# The installation. 
# We actually just put all our install files into a directory structure that mimics a server directory structure here
%install
rm -rf \$RPM_BUILD_ROOT
cp -r ../SOURCES \$RPM_BUILD_ROOT

# Contains a list of the files that are part of the package
# See useful directives such as attr here: http://www.rpm.org/max-rpm-snapshot/s1-rpm-specref-files-list-directives.html
%files
%defattr(755, tomcat, tomcat, -) 
/usr/share/tomcat6/webapps/*
/usr/share/tomcat6/webapps/conf/*

# Used to store any changes between versions
%changelog

%postun
rm -rf /var/lib/tomcat6/webapps/*
rm -rf /var/cache/tomcat6/webapps/*


EOSpec
) > $SPECFILE

cat <<EOF
===========
Your framework for building the "$PACKAGE_NAME" rpm is ready. Your next steps:

    * Place content into ./${PACKAGE_NAME}/SOURCES as if it were the filesystem root.
    * Modify ./${PACKAGE_NAME}/SPECS/${PACKAGE_NAME}.spec accordingly

When you are ready to build the rpm, execute the following from the ./${PACKAGE_NAME}
directory:

    rpmbuild --verbose --define "_topdir \$(pwd)" -ba SPECS/${PACKAGE_NAME}.spec

===========

EOF

### HEREDOC install.sh ###

cat << 'EOT' > /tmp/install.sh

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

EOT

### HEREDOC install.sh ####

### Setup path and copy war files into RPM SOURCES area
echo "### Preparing to copy the following .war files into ./${PACKAGE_NAME}/SOURCES/usr/share/tomcat6/webapps"
ls -l ${PACKAGE_WAR_FILES}/*.war
##cleanup old build files####
rm -rf ./${PACKAGE_NAME}/SOURCES/usr/share/tomcat6/webapps
mkdir -p ./${PACKAGE_NAME}/SOURCES/usr/share/tomcat6/webapps
cp ${PACKAGE_WAR_FILES}/*.war ./${PACKAGE_NAME}/SOURCES/usr/share/tomcat6/webapps
mkdir  ./${PACKAGE_NAME}/SOURCES/usr/share/tomcat6/webapps/conf
if [ -d ${PACKAGE_WAR_FILES}/conf ]
then
	cp -R ${PACKAGE_WAR_FILES}/conf/* ./${PACKAGE_NAME}/SOURCES/usr/share/tomcat6/webapps/conf
else 
	echo "##########No configuration files found  ${PACKAGE_WAR_FILES}/conf/!!!###########"
	exit 1
fi
mkdir -p ./${PACKAGE_NAME}/SOURCES/usr/share/tomcat6/webapps/sh
cp /tmp/install.sh ./${PACKAGE_NAME}/SOURCES/usr/share/tomcat6/webapps/sh

### Invoke RPM build
cd $PACKAGE_NAME
rpmbuild --verbose --define "_topdir $(pwd)" -ba SPECS/${PACKAGE_NAME}.spec

### Copy RPM to somewhere useful
###/home/e741fm/Lab/RPMLAB/ERAC-ENS/RPMS/noarch/ERAC-ENS-0.2-0.noarch.rpm
cd $STARTING_DIRECTORY
echo "### RPM is at ${STARTING_DIRECTORY}/${PACKAGE_NAME}/RPMS/noarch/${PACKAGE_NAME}-${PACKAGE_VERSION}-${PACKAGE_RELEASE}.${PACKAGE_ARCH}.rpm"
ls -l  ${STARTING_DIRECTORY}/${PACKAGE_NAME}/RPMS/noarch/${PACKAGE_NAME}-${PACKAGE_VERSION}-${PACKAGE_RELEASE}.${PACKAGE_ARCH}.rpm
cp ${STARTING_DIRECTORY}/${PACKAGE_NAME}/RPMS/noarch/${PACKAGE_NAME}-${PACKAGE_VERSION}-${PACKAGE_RELEASE}.${PACKAGE_ARCH}.rpm /erac/rpm_Application_Packages/apps
if [ $? -eq 0 ]
then
	echo "${PACKAGE_NAME}-${PACKAGE_VERSION}-${PACKAGE_RELEASE}.${PACKAGE_ARCH}.rpm pushed to /erac/rpm_Application_Packages/apps"
else
	echo "ERROR: ${PACKAGE_NAME}-${PACKAGE_VERSION}-${PACKAGE_RELEASE}.${PACKAGE_ARCH}.rpm could not be pushed to /erac/rpm_Application_Packages/apps verify permissions"
	exit 1
fi

