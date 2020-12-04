#!/bin/bash

#---------------------------------------------------------------------------------------------
# Script Name: maintenance_log-archive.sh
# Created: 2019/11/01
# Modified: 2019/11/01
# Author: Scott Donaldson [VERTIV/AVOCENT/UK]
# Company: Vertiv Infrastructure Ltd.
# Group: Software Delovery, Services
# Email: global.services.delivery.development@vertivco.com
#---------------------------------------------------------------------------------------------


# Clear Screen
echo -en "\ec"

VERSION_STRING=0.1

# Configuration
# TODO: Add detection for WebLogic Domain.
# TODO: Add launch parameter to specify WebLogic Domain.
WL_DOMAIN=TrellisDomain
BACK_SEARCH_DIRS=/u02/app/ /u02/domains/IDMDomain/ /u02/licensing/ /u01/fm/11.1.1.7/asinst_1/diagnostics/ /u01/fm/11.1.1.7/asinst_1/EMAGENT/ /u01/fm/11.1.1.7/oracle_common/ /u01/fm/11.1.1.7/Oracle_IDM1/ /u03/logs/installer/
FRONT_SEARCH_DIRS=/u02/ /u03/logs/installer/
OID_HOME=/u01/fm/11.1.1.7/asinst_1
FILE_AGE_DAYS=7
OUTPUT_DIR=/u03/logs/diagnostics

declare -a wlservers_front=("AdminServer" "adf_server" "soa_server" "osb_server" "jasper_server")
declare -a wlservers_back=("AdminServer" "wls_ods1")
declare -a oidservers=("OVD/ovd1" "OID/oid1" "OPMN/opmn" "OHS/ohs1")

#
#  Check Running User
#
#if [ "$ENV_CURRENT_USER" != "oracle" ]; then
if [ `id -un` != "oracle" ]; then
    echo '[Info]: Script not launched by oracle user.' 2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
    if [ `id -u` -eq 0 ]; then
			echo '[Info]: Script elevated with sudo.' 2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
	else
		echo '[Error]: Script neither elevated with sudo or run by oracle, cannot continue.' 2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
		exit 1
	fi
fi
#####

if [[ $OUTPUT_DIR =~ (^\/tmp\/{0,1}[a-zA-Z0-9\/\.\_\-]{0,})|(^\/var\/tmp\/{0,1}[a-zA-Z0-9]{0,})|(^\/tmp\/{0,1}[a-zA-Z0-9\/\.\_\-]{0,})|(^\/home\/scott\/{0,1}[a-zA-Z0-9\/\.\_\-]{0,})|(^\/u0[35]\/{0,1}[a-zA-Z0-9\/\.\_\-]{0,}) ]]; then
	echo "[Info]: Output directory is safe." 2>&1
	if [[ ! -d $OUTPUT_DIR ]]; then 
		echo "[Info]: Creating output directory $OUTPUT_DIR." 2>&1
		mkdir -p $OUTPUT_DIR
		if [ $? -neq 0 ]; then
			echo "[Error]: Failed to create output directory $OUTPUT_DIR." 2>&1
			exit
		fi
	fi
else
	echo "[Warning]: Output directory is unsafe." 2>&1
	OUTPUT_DIR=/tmp
fi

echo -e "\n################################################################################"
echo -e "#"
echo -e "#\tVertiv Trellis(tm) Enterprise - Log Archive Script $VERSION_STRING"
echo -e "#"
echo -e "################################################################################\n\n"

if [[ -d '/u02/domains/IDMDomain' ]]; then
  echo "[Info]: This is the back server." 2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
  HOST=back
  WL_DOMAIN=IDMDomain
  # TODO: Replace with filename function.
  OUTPUT_TAR=`hostname -s`_trellis-back_logs_`date +"%Y%m%d-%H%M%S%z"`.tar
  OUTPUT_LOG=`hostname -s`_trellis-back_logs_`date +"%Y%m%d-%H%M%S%z"`.log
elif [[ -d '/u02/domains' ]]; then
  # TODO: Improve detection of specific WL domain name,
  echo "[Info]: This is the front server." 2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
  HOST=front
  
  # TODO: Replace with filename function.
  OUTPUT_TAR=`hostname -s`_trellis-front_logs_`date +"%Y%m%d-%H%M%S%z"`.tar
  OUTPUT_LOG=`hostname -s`_trellis-front_logs_`date +"%Y%m%d-%H%M%S%z"`.log
  
  if [[ -e "/etc/sysconfig/trellis" ]]; then
    # TODO: Make this safer by validating the returned value is safe.
	WL_DOMAIN=`cat /etc/sysconfig/trellis | grep -i '^TRELLIS_DOMAIN=' | cut -d '=' -f2 | sed 's/"//g'`
	echo "[Info]: Detected WebLogic Domain ${WL_DOMAIN}." 2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
  else
    echo "[Fatal]: Trellis configuration file missing." 2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
  fi
else
  echo "[Error]: Trellis directories not detected." 2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
  exit -1
fi

##
#  Front Server Log Locations
#
if [ $HOST == 'front' ]; then

	echo "[Info]: Checking directory /u02/domains/${WL_DOMAIN} exists." 2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
	if [[ -d "/u02/domains/${WL_DOMAIN}" ]]; then

	echo "Collecting server logs." | tee -a $OUTPUT_DIR/$OUTPUT_LOG
	wldomainlen=${#wlservers_front[@]}

	# Loop through defined subdomains.
	for ((i=1; i<${wldomainlen}+1; i++)); do
		echo "[Info]: Collecting server ${wlservers_front[$i-1]} logs from /u02/domain/${WL_DOMAIN}."
		find /u02/domains/$WL_DOMAIN/servers/${wlservers_front[$i-1]} -regextype posix-extended -regex '^.*(\.log|\.out|_log\.)[0-9]{0,12}' \
			-type f -newermt $(date +%Y-%m-%d -d "${FILE_AGE_DAYS} day ago") \
			-exec tar -rvf $OUTPUT_DIR/$OUTPUT_TAR {} \; 2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
	done
	else
		echo "[Error]: Directory /u02/domains/${WL_DOMAIN} not detected." 2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
	fi

	if [ -d '/u02/OHS/ui01' ]; then
		echo "[Info]: Collecting OHS ui01 logs." 2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
		find /u02/OHS/ui01/diagnostics/logs/OHS/ohs01/ -regextype posix-extended -regex '^.*(\.log|\.out|_log\.)[0-9]{0,12}' \
			-type f -newermt $(date +%Y-%m-%d -d "${FILE_AGE_DAYS} day ago") \
			-exec tar -rvf $OUTPUT_DIR/$OUTPUT_TAR {} \; 2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
	else
		echo "[Error]: Directory /u02/OHS/ui01/diagnostics/logs/OHS/ohs01 not detected." 2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
	fi

	if [ -d '/u02/OHS/osbproxy01' ]; then
		echo "[Info]: Collecting OHS osbproxy01 logs." 2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
		find /u02/OHS/osbproxy01/diagnostics/logs/OHS/osbproxy01/ -regextype posix-extended -regex '^.*(\.log|\.out|_log\.)[0-9]{0,12}' \
			-type f -newermt $(date +%Y-%m-%d -d "${FILE_AGE_DAYS} day ago") \
			-exec tar -rvf $OUTPUT_DIR/$OUTPUT_TAR {} \; 2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
	else
		echo "[Error]: Directory /u02/OHS/osbproxy01/diagnostics/logs/OHS/osbproxy01 not detected." 2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
	fi

##
#  Back Server Log Locations
#
else
	echo -e "[Working]: Collecting logs, please wait for completion...\n" 2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
	# TODO: Replace with function.
	
	echo "[Info]: Checking directory /u02/domains/${WL_DOMAIN} exists." 2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
	if [[ -d "/u02/domains/${WL_DOMAIN}" ]]; then
		echo -e "[Working]: Purging rotated logs, please wait for completion...\n"
		wldomainlen=${#wlservers_back[@]}

		# Loop through defined subdomains.
		for ((i=1; i<${wldomainlen}+1; i++)); do
			echo "[Info]: Collecting server ${wlservers_back[$i-1]} logs from /u02/domains/$WL_DOMAIN."
			find /u02/domains/$WL_DOMAIN/servers/${wlservers_front[$i-1]} -regextype posix-extended -regex '^.*(\.log|\.out|_log\.)[0-9]{0,12}' \
				-type f -newermt $(date +%Y-%m-%d -d "${FILE_AGE_DAYS} day ago") \
				-exec tar -rvf $OUTPUT_DIR/$OUTPUT_TAR {} \;  2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
		done
	else
		echo "[Info]: Directory /u02/domains/${WL_DOMAIN} not detected." 2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
	fi
	
	wldomainlen=${#oidservers[@]}
		# Loop through defined subdomains.
	for ((i=1; i<${wldomainlen}+1; i++)); do
		echo "[Info]: Collecting ${oidservers[$i-1]} logs." 2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
		find $OID_HOME/diagnostics/logs/${oidservers[$i-1]}/ -regextype posix-extended -regex '^.*(\.log|\.out|_log\.)[0-9]{0,12}' \
			-type f -newermt $(date +%Y-%m-%d -d "${FILE_AGE_DAYS} day ago") \
			-exec tar -rvf $OUTPUT_DIR/$OUTPUT_TAR {} \;  2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
	done
	
	if [ -d '/u02/app/oracle/diag' ]; then
		echo "[Info]: Collecting database logs." 2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
		find /u02/app/oracle/diag/ -regextype posix-extended -regex '^.*(\.log|\.out|_log)[0-9]{0,12}' \
			-type f -newermt $(date +%Y-%m-%d -d "${FILE_AGE_DAYS} day ago") \
			-exec tar -rvf $OUTPUT_DIR/$OUTPUT_TAR {} \; 2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
		find /u02/app/oracle/diag/ -regextype posix-extended -regex '^.*(\.log|.trc|\.trm|\.log\.backup)[0-9]{0,12}' \
			-type f -newermt $(date +%Y-%m-%d -d "${FILE_AGE_DAYS} day ago") \
			-exec tar -rvf $OUTPUT_DIR/$OUTPUT_TAR {} \; 2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
		find /u02/app/oracle/diag/ -regextype posix-extended -regex '^log_[0-9]{0,12}\.xml' \
			-type f -newermt $(date +%Y-%m-%d -d "${FILE_AGE_DAYS} day ago") \
			-exec tar -rvf $OUTPUT_DIR/$OUTPUT_TAR {} \; 2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
	else
		echo "[Error]: Directory /u02/app/oracle/diag not detected." 2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
	fi

fi

echo "[Info]: Processing archive file..." 2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
if [[ -e $OUTPUT_DIR/$OUTPUT_TAR ]]; then
	gzip $OUTPUT_DIR/$OUTPUT_TAR  2>&1 | tee -a $OUTPUT_DIR/$OUTPUT_LOG
	#TODO: Verify command succeeded.
	#TODO: Implement AES encryption of GZ with OpenSSL.
	#TODO: Update final name.
fi


echo -e "[Info]: Logs archive saved to $OUTPUT_DIR/$OUTPUT_TAR.gz"
echo -e "[Info]: Logs saved to $OUTPUT_DIR/$OUTPUT_LOG"
echo -e "\nDone.\n"

exit
