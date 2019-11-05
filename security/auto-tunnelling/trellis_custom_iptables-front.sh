
##
#  Early Pass Loopback
#
iptables -A INPUT -i lo -j ACCEPT

##
#  Early Drop Malfromed/Spoofed Packets (Inbound)
#
iptables -A INPUT ! -i lo -s 127.0.0.0/8 -j REJECT
iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
iptables -A INPUT -f -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ACK,RST,SYN,FIN -j DROP
iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP


##
#  Early Drop Malfromed/Spoofed Packets (Inbound)
#
iptables -A OUTPUT -m state --state INVALID -j DROP
iptables -A OUTPUT -p tcp --tcp-flags ALL ACK,RST,SYN,FIN -j DROP
iptables -A OUTPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
iptables -A OUTPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP

##
#  Inbound State Tracking
#
iptables -A INPUT -m state --state INVALID -j DROP
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
#iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 6443 -j ACCEPT
iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 7002 -j ACCEPT
iptables -A INPUT -p icmp -m state --state NEW -m icmp --icmp-type echo-request  -j ACCEPT

##
#
#
iptables -A INPUT -i eth0 -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp -m state --state NEW -m tcp --dport 7021 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp -m state --state NEW -m tcp --dport 7026 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp -m state --state NEW -m tcp --dport 1521 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp -m state --state NEW -m tcp --dport 8080 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp -m state --state NEW -m tcp --dport 7024 -j ACCEPT
iptables -A INPUT -j DROP 


##
# Redirect to NAT (DNAT)
#
iptables -t nat -A PREROUTING -p tcp -m state --state NEW,RELATED,ESTABLISHED -m tcp -d trellis-back --dport 1521 -j DNAT --to-destination 127.0.0.1:11521
iptables -t nat -A PREROUTING -p tcp -m state --state NEW,RELATED,ESTABLISHED -m tcp -d trellis-back --dport 7021 -j DNAT --to-destination 127.0.0.1:17021
iptables -t nat -A PREROUTING -p tcp -m state --state NEW,RELATED,ESTABLISHED -m tcp -d trellis-back --dport 7024 -j DNAT --to-destination 127.0.0.1:17024
iptables -t nat -A PREROUTING -p tcp -m state --state NEW,RELATED,ESTABLISHED -m tcp -d trellis-back --dport 7026 -j DNAT --to-destination 127.0.0.1:17026
iptables -t nat -A PREROUTING -p tcp -m state --state NEW,RELATED,ESTABLISHED -m tcp -d trellis-back --dport 8080 -j DNAT --to-destination 127.0.0.1:18080

##
# Redirect Output to Localhost SSH Ports
#
iptables -t nat -A OUTPUT -p tcp -d trellis-back --dport 7026 -j DNAT --to-destination 127.0.0.1:17026
iptables -t nat -A OUTPUT -p tcp -d trellis-back --dport 1521 -j DNAT --to-destination 127.0.0.1:11521
iptables -t nat -A OUTPUT -p tcp -d trellis-back --dport 8080 -j DNAT --to-destination 127.0.0.1:18080
iptables -t nat -A OUTPUT -p tcp -d trellis-back --dport 7024 -j DNAT --to-destination 127.0.0.1:17024
iptables -t nat -A OUTPUT -p tcp -d trellis-back --dport 7021 -j DNAT --to-destination 127.0.0.1:17021

##
#  Output Whitelist Loopback
#
#iptables -A OUTPUT -o lo -j ACCEPT

##
#  Output Constraints
#
#iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
#iptables -A OUTPUT -o eth0 -d trellis-back -j ACCEPT
#iptables -A OUTPUT -o eth0 -d 10.0.0.0/24 -j ACCEPT

##
#  Permit Output Types
#
#iptables -A OUTPUT -p udp -d 9.9.9.9/32 --dport 53 -m state --state NEW -j ACCEPT
#iptables -A OUTPUT -p tcp -d 9.9.9.9/32 --dport 53 -m state --state NEW -j ACCEPT
#iptables -A OUTPUT -p tcp -d 0.0.0.0/0 --dport 22 -m state --state NEW -j ACCEPT
#iptables -A OUTPUT -p tcp -d 0.0.0.0/0 --dport 80 -m state --state NEW -j ACCEPT
#iptables -A OUTPUT -p tcp -d 0.0.0.0/0 --dport 443 -m state --state NEW -j ACCEPT

##
#  Default Output
#
#iptables -A OUTPUT -j DROP

##
#  Forwarding Constraints
#
iptables -A FORWARD -j DROP

