

echo -e "\n################################################################################"
echo -e "#"
echo -e "#\tVertiv Trellis(tm) Enterprise - Cipher Test $VERSION_STRING"
echo -e "#"
echo -e "################################################################################\n\n"

printf "%-20s %-50s\n" "Hostname:" "$target_host"
printf "%-20s %-50s\n" "Port:" "$target_port"

read -a ciphers <<< $(openssl ciphers 'ALL:eNULL' | tr ':' ' ')
declare -a protocols=("ssl2" "ssl3" "tlsv1" "tls1_1" "tls1_2" "tls1_3")
protocolslen=${#protocols[@]}
cipherslen=${#ciphers[@]}

for ((i=1; i<${protocolslen}+1; i++)); do
	echo -e "\n[Info]: Testing protocol ${protocols[$i-1]}\n"
	echo -e "[Info]: Testing ciphers:"
	for ((j=1; j<${cipherslen}+1; j++)); do
		#echo -e "\t${ciphers[$j-1]}"
		openssl s_client -${protocols[$i-1]} -connect ${target_host}:${target_port} -cipher ${ciphers[$j-1]} < /dev/null > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			#echo -e "\t${ciphers[$j-1]}:\t\tOK"
			printf "%-10s %-50s | %-20b\n" " " "${ciphers[$j-1]}" "${GREEN}ACCEPTED${NONE}"
		else
			#echo -e "\t${ciphers[$j-1]}:\t\tREJECTED"
			if [ "$CFG_OUTPUT_REJECTED" = true ]; then 
				printf "%-10s %-50s | %-20b\n" " " "${ciphers[$j-1]}" "${RED}REJECTED${NONE}"
			fi
		fi
	done
done

echo -e "\nComplete."