#!/bin/bash

##
#
# Title:		AD Discovery Validation
# Description:  Discovers AD controllers from DNS SRV records
# Version:		0.1
# Authors: 		scott.donaldson@vertiv.com
# Usage:		./maintenance_ad-discovery.sh
# 

#
# The following are used for terminal output
#
NONE='\033[00m'
RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
PURPLE='\033[01;35m'
CYAN='\033[01;36m'
WHITE='\033[01;37m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
#####

CFG_OUTPUT_REJECTED=$true
OUTPUT_DIR=/u03/logs/diagnostics
OUTPUT_LOG=`hostname -s`_ad-discovery-test-`date +"%Y%m%d-%H%M%S"`.log

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

# Clear Screen
echo -en "\ec"

VERSION_STRING=0.2

echo -e "\n################################################################################"
echo -e "#"
echo -e "#\tVertiv Trellis(tm) Enterprise - AD Discovery Test $VERSION_STRING"
echo -e "#"
echo -e "################################################################################\n\n"

declare -a INSECURE_PORTS=( 389 3268 )
declare -a SECURE_PORTS=( 636 3269 )

kinit -k host/$(hostname -f) 2> /dev/null | tee -a $OUTPUT_DIR/$OUTPUT_LOG
if [ $? -eq 0 ]; then
	TARGET_DOMAIN=example.org
else
	#TODO: Implement domain handling.
	TARGET_DOMAIN=example.org
fi

function verify_secure() {
	local target_host="$1"
	local target_port="$2"

	# TODO: Clean this up, as this is really inefficient to do on each itteration.
	read -a ciphers <<< $(openssl ciphers 'ALL:eNULL' | tr ':' ' ')
	local -a protocols=("ssl3" "tlsv1" "tls1_1" "tls1_2" "tls1_3")

	protocolslen=${#protocols[@]}
	cipherslen=${#ciphers[@]}
	
	timeout 3 openssl s_client -connect ${target_host}:${target_port} -showcerts 2> /dev/null  | tee -a $OUTPUT_DIR/$OUTPUT_LOG
	
	if [ $? -eq 0 ]; then
		printf "\n%-10s %-50s %-10b %-10b\n" "" "Cipher" "Protocol" "Status" | tee -a $OUTPUT_DIR/$OUTPUT_LOG
		
		for ((i=1; i<${protocolslen}+1; i++)); do
			for ((j=1; j<${cipherslen}+1; j++)); do
				openssl s_client -${protocols[$i-1]} -connect ${target_host}:${target_port} -cipher ${ciphers[$j-1]} < /dev/null > /dev/null 2>&1
				if [ $? -eq 0 ]; then
					printf "%-10s %-50s %-10b %-10b\n" "" "${ciphers[$j-1]}" "${protocols[$i-1]}" "${GREEN}ACCEPTED${NONE}" | tee -a $OUTPUT_DIR/$OUTPUT_LOG
				else
					printf "%-10s %-50s %-10b %-10b\n" "" "${ciphers[$j-1]}" "${protocols[$i-1]}" "${RED}REJECTED${NONE}" | tee -a $OUTPUT_DIR/$OUTPUT_LOG
				fi
			done
		done
	else
		printf "%-20s %-50s %-10b %-10b\n" "" "${ciphers[$j-1]}" "${protocols[$i-1]}" "${RED}FAILED${NONE}" | tee -a $OUTPUT_DIR/$OUTPUT_LOG
	fi
}

function detect_controllers() {
	local DOMAIN="$1"
	local -a AD_CONTROLLERS=(`dig _ldap._tcp.dc._msdcs.${DOMAIN} SRV +short +stats +tcp | sed -r -e 's/[0-9]{1,3}\s[0-9]{1,3}\s[0-9]{1,5}\s//g'`)
	declare -p AD_CONTROLLERS
}


echo -n "Discover AD controllers? (y/n)? "
old_stty_cfg=$(stty -g)
stty raw -echo
answer=$( while ! head -c 1 | grep -i '[ny]' ;do true ;done )
stty $old_stty_cfg

if echo "$answer" | grep -iq "^y" ;then
	echo "[Info]: Target domain ${TARGET_DOMAIN}."
	ret=`detect_controllers $TARGET_DOMAIN`
	
	eval "declare -a AD_CONTROLLERS=${ret}" 2> /dev/null
	
	#echo "[Info]: Identified controllers ${AD_CONTROLLERS[@]}." | tee -a $OUTPUT_DIR/$OUTPUT_LOG
	
	printf "\n%-20s %-50s %-10s %-10s\n" "Controller:" "" "" "" | tee -a $OUTPUT_DIR/$OUTPUT_LOG
	i=0
	for controller in "${AD_CONTROLLERS[@]}"
	do
		((i++))
		printf "%-20s %-50s %-10s %-10s\n" "$i" "$controller" "" "" | tee -a $OUTPUT_DIR/$OUTPUT_LOG
	done
	
	i=0
	for controller in "${AD_CONTROLLERS[@]}"
	do
		((i++))
		printf "\n%-20s %-50s %-10s %-10s\n" "Controller" "Hostname" "Port" "" | tee -a $OUTPUT_DIR/$OUTPUT_LOG
		for port in "${INSECURE_PORTS[@]}"; do
			printf "%-20s %-50s %-10s %-10s\n" "$i" "$controller" "TCP/$port" "" | tee -a $OUTPUT_DIR/$OUTPUT_LOG
		done
		for port in "${SECURE_PORTS[@]}"; do
			printf "%-20s %-50s %-10s %-10s\n" "$i" "$controller" "TCP/$port" "" | tee -a $OUTPUT_DIR/$OUTPUT_LOG
			verify_secure $controller $port
		done
	done
else
    echo "[Info]: Exiting script." | tee -a $OUTPUT_DIR/$OUTPUT_LOG
fi

exit