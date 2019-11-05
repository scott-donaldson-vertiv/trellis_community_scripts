#!/bin/bash

#---------------------------------------------------------------------------------------------
# Script Name: DNSChecks
# Created: 2019/10/23
# Author:  Scott Donaldson [NETPWR/AVOCENT/UK]
# Contributors: Scott Donaldson [NETPWR/AVOCENT/UK]
# Company: Vertiv Infrastructure Ltd.
# Group: Professional Services
# Email:
#---------------------------------------------------------------------------------------------

DIG_OUTPUT=/tmp/devclone_trellis-back_dig-domain-`date +"%Y%m%d-%H%M%S"`.log
ITTERATIONS=100
PAUSE=2
OPTIONS=+short +stats

# TODO: Implement DNS server argument
# TODO: Impement domain argument
# TODO: Implement domain detection option
DNS_IP=1.2.3.4
domain_forest=example.net

# TODO: Impement sub domain handling.
declare -a subdomains=("sub1" "sub2" "sub3")

echo "Testing DNS responses." | tee -a $DIG_OUTPUT
for (( c=1; c<=$ITTERATIONS; c++)); do

  echo -e "\n###\n# Itteration $c\n#" | tee -a $DIG_OUTPUT

  # List forest.
  echo -e "[Info]: Qury DNS w/ UDP\n#" | tee -a $DIG_OUTPUT
  dig @${DNS_IP} _ldap._tcp.dc._msdcs.${domain_forest} SRV ${OPTIONS} +notcp 2>&1 | tee -a $DIG_OUTPUT 
  dig @${DNS_IP} _kerberos._tcp.dc.msdcs.${domain_forest} SRV ${OPTIONS} +notcp 2>&1 | tee -a $DIG_OUTPUT
  echo -e "[Info]: Qury DNS w/ TCP" | tee -a $DIG_OUTPUT
  dig @${DNS_IP} _ldap._tcp.dc._msdcs.${domain_forest} SRV ${OPTIONS} +tcp 2>&1 | tee -a $DIG_OUTPUT
  dig @${DNS_IP} _kerberos._tcp.dc.msdcs.${domain_forest} SRV ${OPTIONS} +tcp 2>&1 | tee -a $DIG_OUTPUT
  

  subdomainlen=${#subdomains[@]}
  echo "[Debug]: Subdomains specified $subdomainlen" | tee -a $DIG_OUTPUT

  # Loop through defined subdomains.
  for ((i=1; i<${subdomainlen}+1; i++)); do
    echo -e "[Info]: Query sub domain ${subdomains[$i-1]}"  | tee -a $DIG_OUTPUT
    echo -e "[Info]: Qury DNS w/ UDP" | tee -a $DIG_OUTPUT
    dig @${DNS_IP} _ldap._tcp.dc._msdcs.${subdomains[$i-1]}.${domain_forest} SRV ${OPTIONS} +notcp 2>&1 | tee -a $DIG_OUTPUT 
    dig @${DNS_IP} _kerberos._tcp.dc.msdcs.${subdomains[$i-1]}.${domain_forest} SRV ${OPTIONS} +notcp 2>&1 | tee -a $DIG_OUTPUT

    echo -e "[Info]: Qury DNS w/ TCP" | tee -a $DIG_OUTPUT
    dig @${DNS_IP} _ldap._tcp.dc._msdcs.${subdomains[$i-1]}.${domain_forest} SRV ${OPTIONS} +tcp 2>&1 | tee -a $DIG_OUTPUT
    dig @${DNS_IP} _kerberos._tcp.dc.msdcs.${subdomains[$i-1]}.${domain_forest} SRV ${OPTIONS} +tcp  2>&1 | tee -a $DIG_OUTPUT

  done

  echo -e "[Info]: Waiting for next itteration."  | tee -a $DIG_OUTPUT

  sleep $PAUSE
  
done

