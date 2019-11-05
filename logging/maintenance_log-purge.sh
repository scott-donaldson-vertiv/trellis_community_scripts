#!/bin/bash

#---------------------------------------------------------------------------------------------
# Script Name: maintenance_log-purge.sh
# Created: 2019/01/14
# Modified: 2019/03/08
# Author: Scott Donaldson [VERTIV/AVOCENT/UK]
# Company: Vertiv Infrastructure Ltd.
# Group: Software Delovery, Services
# Email: global.services.delivery.development@vertivco.com
#---------------------------------------------------------------------------------------------


# Clear Screen
echo -en "\ec"

VERSION_STRING=0.1

# Configuration
WL_DOMAIN=TrellisDomain
CFG_DELETE_LOG=log-purge_`date +"%Y%m%d-%H%M%S"`.log
BACK_SEARCH_DIRS=/u02/app/ /u02/domains/IDMDomain/ /u02/licensing/
FRONT_SEARCH_DIRS=/u02/

#
#  Check Running User
#
if [ "$ENV_CURRENT_USER" != "oracle" ]; then
    echo '[Info]: Script not launched by oracle user.'> `tty`
    if [ `id -u` -eq 0 ]; then
			echo '[Info]: Script elevated with sudo.'> `tty`
	else
		echo '[Error]: Script neither elevated with sudo or run by oracle, cannot continue.'> `tty`
		exit 1
	fi
fi
#####

echo -e "\n################################################################################"
echo -e "#"
echo -e "#\tVertiv Trellis(tm) Enterprise - Log Purge"
echo -e "#"
echo -e "################################################################################\n\n"

if [[ -d '/u02/domains/IDMDomain' ]]; then
  echo "[Info]: This is the back server."
  HOST=back
elif [[ -d '/u02/domains' ]]; then
  # TODO: Improve detection of specific WL domain name,
  echo "[Info]: This is the front server."
  HOST=front
else
  echo "[Error]: Trellis directories not detected."
  exit -1
fi

##
#  Front Server Log Locations
#
if [ $HOST == 'front' ]; then

  echo -e "[Working]: Purging rotated logs, please wait for completion...\n"

  echo "[Working]: Calculating logging disk usage..."
  DISK_USAGE=`find ${FRONT_SEARCH_DIRS} -type f \( -iname '*_log*' -o -iname '*.log*' -o -iname '*.out*' \) -exec du -ch {} + | grep total$ | egrep -o '[0-9]{1,}\.{0,1}[0-9]{1,}[MmGgTtKk]'`
  echo -e "\n\t$DISK_USAGE\n"

  if [ -d '/u02/domain/$WL_DOMAIN' ]; then
    rm -rfv /u02/domain/$WL_DOMAIN/servers/AdminServer/logs/*.log* 2>&1 >> $CFG_DELETE_LOG
    rm -rfv /u02/domain/$WL_DOMAIN/servers/AdminServer/logs/*.out* 2>&1 >> $CFG_DELETE_LOG
    rm -rfv /u02/domain/$WL_DOMAIN/servers/adf_server/logs/*.log* 2>&1 >> $CFG_DELETE_LOG
    rm -rfv /u02/domain/$WL_DOMAIN/servers/adf_server/logs/*.out* 2>&1 >> $CFG_DELETE_LOG
    rm -rfv /u02/domain/$WL_DOMAIN/servers/osb_server/logs/*.log* 2>&1 >> $CFG_DELETE_LOG
    rm -rfv /u02/domain/$WL_DOMAIN/servers/osb_server/logs/*.out* 2>&1 >> $CFG_DELETE_LOG
    rm -rfv /u02/domain/$WL_DOMAIN/servers/soa_server/logs/*.log* 2>&1 >> $CFG_DELETE_LOG
    rm -rfv /u02/domain/$WL_DOMAIN/servers/soa_server/logs/*.out* 2>&1 >> $CFG_DELETE_LOG
    rm -rfv /u02/domain/$WL_DOMAIN/servers/jasper_server/logs/*.log* 2>&1 >> $CFG_DELETE_LOG
    rm -rfv /u02/domain/$WL_DOMAIN/servers/jasper_server/logs/*.out* 2>&1 >> $CFG_DELETE_LOG
  fi

  if [ -d '/u02/OHS/ui01' ]; then
    rm -rfv /u02/OHS/ui01/diagnostics/logs/OHS/ohs01/access_log* 2>&1 >> $CFG_DELETE_LOG
    rm -rfv /u02/OHS/ui01/diagnostics/logs/OHS/ohs01/ohs01-*.log 2>&1 >> $CFG_DELETE_LOG
  fi

  if [ -d '/u02/OHS/osbproxy01' ]; then
    rm -rfv /u02/OHS/osbproxy01/diagnostics/logs/OHS/osbproxy01/access_log* 2>&1 >> $CFG_DELETE_LOG
    rm -rfv /u02/OHS/osbproxy01/diagnostics/logs/OHS/osbproxy01/osbproxy01-*.log 2>&1 >> $CFG_DELETE_LOG
  fi

  echo "[Info]: Calculating logging disk usage after cleanup."
  DISK_USAGE=`find $FRONT_SEARCH_DIRS -type f \( -iname '*_log*' -o -iname '*.log*' -o -iname '*.out*' \) -exec du -ch {} + | grep total$ | egrep -o '[0-9]{1,}\.{0,1}[0-9]{1,}[MmGgTtKk]'`
  echo -e "\n\t$DISK_USAGE\n"

##
#  Back Server Log Locations
#
else
  echo "[Working]: Calculating logging disk usage..."
  DISK_USAGE=`find $BACK_SEARCH_DIRS -type f \( -iname '*_log*' -o -iname '*.log*' -o -iname '*.out*' \) -exec du -ch {} + | grep total$ | egrep -o '[0-9]{1,}\.{0,1}[0-9]{1,}[MmGgTtKk]'`
  echo -e "\n\t$DISK_USAGE\n"

  echo -e "[Working]: Purging rotated logs, please wait for completion...\n"
  rm -rfv /u02/domains/IDMDomain/servers/wls_ods1/logs/*.log.gz 2>&1 >> $CFG_DELETE_LOG
  rm -rfv /u02/domains/IDMDomain/servers/wls_ods1/logs/*.log* 2>&1 >> $CFG_DELETE_LOG
  rm -rfv /u02/domains/IDMDomain/servers/wls_ods1/logs/*.out* 2>&1 >> $CFG_DELETE_LOG
  rm -rfv /u02/domains/IDMDomain/servers/AdminServer/logs/*.log* 2>&1 >> $CFG_DELETE_LOG
  rm -rfv /u02/domains/IDMDomain/servers/AdminServer/logs/*.out* 2>&1 >> $CFG_DELETE_LOG
  rm -rfv /u02/domains/IDMDomain/servers/AdminServer/data/ldap/log/*.log* 2>&1 >> $CFG_DELETE_LOG
  rm -rfv /u02/domains/IDMDomain/servers/AdminServer/data/ldap/log/*.out* 2>&1 >> $CFG_DELETE_LOG
  rm -rfv /u02/domains/IDMDomain/servers/AdminServer/logs/metrics/*.log.gz 2>&1 >> $CFG_DELETE_LOG

  echo "[Info]: Calculating logging disk usage after cleanup."
  DISK_USAGE=`find $BACK_SEARCH_DIRS -type f \( -iname '*_log*' -o -iname '*.log*' -o -iname '*.out*' \) -exec du -ch {} + | grep total$ | egrep -o '[0-9]{1,}\.{0,1}[0-9]{1,}[MmGgTtKk]'`
  echo -e "\n\t$DISK_USAGE\n"

fi

echo "[Info]: Deletion history has been saved to $CFG_DELETE_LOG".
echo -e "\nDone.\n"

exit
