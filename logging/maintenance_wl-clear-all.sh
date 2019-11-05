#!/bin/bash

#---------------------------------------------------------------------------------------------
# Script Name: maintenance_log-purge.sh
# Created: 2019/01/14
# Modified: 2019/10/23
# Author: Scott Donaldson [VERTIV/AVOCENT/UK]
# Company: Vertiv Infrastructure Ltd.
# Group: Software Delovery, Services
# Email: global.services.delivery.development@vertivco.com
#---------------------------------------------------------------------------------------------

# Clear Screen
echo -en "\ec"

VERSION_STRING=0.2

# Configuration
# TODO: Add detection for WebLogic Domain.
# TODO: Add launch parameter to specify WebLogic Domain.
WL_DOMAIN=TrellisDomainDevTest
CFG_LOG_OUTPUT=log-purge_`date +"%Y%m%d-%H%M%S"`.log
BACK_SEARCH_DIRS=/u02/app/ /u02/domains/IDMDomain/ /u02/licensing/ /u01/fm/11.1.1.7/asinst_1/diagnostics/
FRONT_SEARCH_DIRS=/u02/
OID_HOME=/u01/fm/11.1.1.7/asinst_1

declare -a wlservers_front=("AdminServer" "adf_server" "soa_server" "osb_server" "jasper_server")
declare -a wlservers_back=("AdminServer" "wls_ods1")
declare -a oidservers=("OVD/ovd1" "OID/oid1" "OPMN/opmn" "OHS/ohs1")

#
#  Check Running User
#
#if [ "$ENV_CURRENT_USER" != "oracle" ]; then
if [ `id -un` != "oracle" ]; then
    echo '[Info]: Script not launched by oracle user.' 2>&1 | tee -a $CFG_LOG_OUTPUT
    if [ `id -u` -eq 0 ]; then
			echo '[Info]: Script elevated with sudo.' 2>&1 | tee -a $CFG_LOG_OUTPUT
	else
		echo '[Error]: Script neither elevated with sudo or run by oracle, cannot continue.' 2>&1 | tee -a $CFG_LOG_OUTPUT
		exit 1
	fi
fi
#####

echo -e "\n################################################################################"
echo -e "#"
echo -e "#\tVertiv Trellis(tm) Enterprise - Log & Temp Purge Script $VERSION_STRING"
echo -e "#"
echo -e "################################################################################\n\n"

if [[ -d '/u02/domains/IDMDomain' ]]; then
  echo "[Info]: This is the back server." 2>&1 | tee -a $CFG_LOG_OUTPUT
  HOST=back
elif [[ -d '/u02/domains' ]]; then
  # TODO: Improve detection of specific WL domain name,
  echo "[Info]: This is the front server." 2>&1 | tee -a $CFG_LOG_OUTPUT
  HOST=front
  if [[ -e "/etc/sysconfig/trellis" ]]; then
    # TODO: Make this safer by validating the returned value is safe.
	WL_DOMAIN=`cat /etc/sysconfig/trellis | grep -i '^TRELLIS_DOMAIN=' | cut -d '=' -f2 | sed 's/"//g'`
	echo "[Info]: Detected WebLogic Domain ${WL_DOMAIN}." 2>&1 | tee -a $CFG_LOG_OUTPUT
  else
    echo "[Fatal]: Trellis configuration file missing." 2>&1 | tee -a $CFG_LOG_OUTPUT
  fi
else
  echo "[Error]: Trellis directories not detected." 2>&1 | tee -a $CFG_LOG_OUTPUT
  exit -1
fi

##
#  Front Server Log Locations
#
if [ $HOST == 'front' ]; then

  echo -e "[Working]: Purging rotated logs, please wait for completion...\n" 2>&1 | tee -a $CFG_LOG_OUTPUT
  
  # TODO: Test for server lock files under /u02/domains/$WL_DOMAIN/servers/$wlservers_front[n]/tmp/$wlservers_front[n].lok

  echo "[Working]: Calculating logging disk usage..." 2>&1 | tee -a $CFG_LOG_OUTPUT
  DISK_USAGE=`find ${FRONT_SEARCH_DIRS} -type f \( -iname '*_log*' -o -iname '*.log*' -o -iname '*.out*' \) -exec du -ch {} + | grep total$ | egrep -o '[0-9]{1,}\.{0,1}[0-9]{1,}[MmGgTtKk]'`
  echo -e "\n\t$DISK_USAGE\n" 2>&1 | tee -a $CFG_LOG_OUTPUT

  echo "[Info]: Checking directory /u02/domains/${WL_DOMAIN} exists."
  if [[ -d "/u02/domains/${WL_DOMAIN}" ]]; then
  
	echo "Clearing server directories." | tee -a $CFG_LOG_OUTPUT
	wldomainlen=${#wlservers_front[@]}

	# Loop through defined subdomains.
	for ((i=1; i<${wldomainlen}+1; i++)); do
		echo "[Info]: Clearing server ${wlservers_front[$i-1]} temporary content & logs from /u02/domain/${WL_DOMAIN}."
		rm -rfv /u02/domains/$WL_DOMAIN/servers/${wlservers_front[$i-1]}/cache/* 2>&1 | tee -a $CFG_LOG_OUTPUT
		rm -rfv /u02/domains/$WL_DOMAIN/servers/${wlservers_front[$i-1]}/tmp/* 2>&1 | tee -a $CFG_LOG_OUTPUT
		rm -rfv /u02/domains/$WL_DOMAIN/servers/${wlservers_front[$i-1]}/stage/* 2>&1 | tee -a $CFG_LOG_OUTPUT
		rm -fv /u02/domains/$WL_DOMAIN/servers/${wlservers_front[$i-1]}/logs/*.log* 2>&1 | tee -a $CFG_LOG_OUTPUT
		rm -fv /u02/domains/$WL_DOMAIN/servers/${wlservers_front[$i-1]}/logs/*.out* 2>&1 | tee -a $CFG_LOG_OUTPUT
		rm -fv /u02/domains/$WL_DOMAIN/servers/${wlservers_front[$i-1]}/data/ldap/log/*.log* 2>&1 | tee -a $CFG_LOG_OUTPUT
		rm -fv /u02/domains/$WL_DOMAIN/servers/${wlservers_front[$i-1]}/data/ldap/log/*.out* 2>&1 | tee -a $CFG_LOG_OUTPUT
		rm -fv /u02/domains/$WL_DOMAIN/servers/${wlservers_front[$i-1]}/logs/metrics/*.log.gz 2>&1 | tee -a $CFG_LOG_OUTPUT
	done
  else
	echo "[Info]: Directory /u02/domains/${WL_DOMAIN} not detected."
  fi

  if [ -d '/u02/OHS/ui01' ]; then
    rm -rfv /u02/OHS/ui01/diagnostics/logs/OHS/ohs01/access_log* 2>&1 | tee -a $CFG_LOG_OUTPUT
    rm -rfv /u02/OHS/ui01/diagnostics/logs/OHS/ohs01/ohs01-*.log  2>&1 | tee -a $CFG_LOG_OUTPUT
  fi

  if [ -d '/u02/OHS/osbproxy01' ]; then
    rm -rfv /u02/OHS/osbproxy01/diagnostics/logs/OHS/osbproxy01/access_log*  2>&1 | tee -a $CFG_LOG_OUTPUT
    rm -rfv /u02/OHS/osbproxy01/diagnostics/logs/OHS/osbproxy01/osbproxy01-*.log  2>&1 | tee -a $CFG_LOG_OUTPUT
  fi

  echo "[Info]: Calculating logging disk usage after cleanup." 2>&1 | tee -a $CFG_LOG_OUTPUT
  DISK_USAGE=`find $FRONT_SEARCH_DIRS -type f \( -iname '*_log*' -o -iname '*.log*' -o -iname '*.out*' \) -exec du -ch {} + | grep total$ | egrep -o '[0-9]{1,}\.{0,1}[0-9]{1,}[MmGgTtKk]'`
  echo -e "\n\t$DISK_USAGE\n" 2>&1 | tee -a $CFG_LOG_OUTPUT

##
#  Back Server Log Locations
#
else
	echo "[Working]: Calculating logging disk usage..." 2>&1 | tee -a $CFG_LOG_OUTPUT
	DISK_USAGE=`find $BACK_SEARCH_DIRS -type f \( -iname '*_log*' -o -iname '*.log*' -o -iname '*.out*' \) -exec du -ch {} + | grep total$ | egrep -o '[0-9]{1,}\.{0,1}[0-9]{1,}[MmGgTtKk]'`
	echo -e "\n\t$DISK_USAGE\n" 2>&1 | tee -a $CFG_LOG_OUTPUT
	WL_DOMAIN=IDMDomain
	
	echo "[Info]: Checking directory /u02/domains/${WL_DOMAIN} exists."
	if [[ -d "/u02/domains/${WL_DOMAIN}" ]]; then
		echo -e "[Working]: Purging rotated logs, please wait for completion...\n"
		wldomainlen=${#wlservers_back[@]}

		# Loop through defined subdomains.
		for ((i=1; i<${wldomainlen}+1; i++)); do
			echo "[Info]: Clearing server ${wlservers_back[$i-1]} temporary content & logs."
			rm -rfv /u02/domains/$WL_DOMAIN/servers/${wlservers_back[$i-1]}/cache/* 2>&1 | tee -a $CFG_LOG_OUTPUT
			rm -rfv /u02/domains/$WL_DOMAIN/servers/${wlservers_back[$i-1]}/tmp/* 2>&1 | tee -a $CFG_LOG_OUTPUT
			rm -rfv /u02/domains/$WL_DOMAIN/servers/${wlservers_back[$i-1]}/stage/* 2>&1 | tee -a $CFG_LOG_OUTPUT
			rm -fv /u02/domains/$WL_DOMAIN/servers/${wlservers_back[$i-1]}/logs/*.log* 2>&1 | tee -a $CFG_LOG_OUTPUT
			rm -fv /u02/domains/$WL_DOMAIN/servers/${wlservers_back[$i-1]}/logs/*.out* 2>&1 | tee -a $CFG_LOG_OUTPUT
			rm -fv /u02/domains/$WL_DOMAIN/servers/${wlservers_back[$i-1]}/data/ldap/log/*.log* 2>&1 | tee -a $CFG_LOG_OUTPUT
			rm -fv /u02/domains/$WL_DOMAIN/servers/${wlservers_back[$i-1]}/data/ldap/log/*.out* 2>&1 | tee -a $CFG_LOG_OUTPUT
			rm -fv /u02/domains/$WL_DOMAIN/servers/${wlservers_back[$i-1]}/logs/metrics/*.log.gz 2>&1 | tee -a $CFG_LOG_OUTPUT
		done
	else
		echo "[Info]: Directory /u02/domains/${WL_DOMAIN} not detected."
	fi
	
	wldomainlen=${#oidservers[@]}
		# Loop through defined subdomains.
	for ((i=1; i<${wldomainlen}+1; i++)); do
		echo "[Info]: Clearing ${oidservers[$i-1]} logs."
		rm -fv $OID_HOME/diagnostics/logs/${oidservers[$i-1]}/*.log* 2>&1 | tee -a $CFG_LOG_OUTPUT
		rm -fv $OID_HOME/diagnostics/logs/${oidservers[$i-1]}/*.out* 2>&1 | tee -a $CFG_LOG_OUTPUT
	done

	echo "[Info]: Calculating logging disk usage after cleanup." 2>&1 | tee -a $CFG_LOG_OUTPUT
	DISK_USAGE=`find $BACK_SEARCH_DIRS -type f \( -iname '*_log*' -o -iname '*.log*' -o -iname '*.out*' \) -exec du -ch {} + | grep total$ | egrep -o '[0-9]{1,}\.{0,1}[0-9]{1,}[MmGgTtKk]'`
	echo -e "\n\t$DISK_USAGE\n"  2>&1 | tee -a $CFG_LOG_OUTPUT

fi

echo "[Info]: Deletion history has been saved to $CFG_LOG_OUTPUT".
echo -e "\nDone.\n"

exit
