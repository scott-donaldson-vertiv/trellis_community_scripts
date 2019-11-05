#!bin/bash

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
#iptables -A INPUT -i eth0 -p tcp ! --syn -m state --state NEW -j DROP
iptables -A INPUT -i eth0 -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
#iptables -A INPUT -i eth0 -p tcp -s trellis-front -m state --state NEW -m tcp --dport 1521 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp -s trellis-front -m state --state NEW -m tcp --dport 1158 -j ACCEPT
#iptables -A INPUT -i eth0 -p tcp -s trellis-front -m state --state NEW -m tcp --dport 7021 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp -s trellis-front -m state --state NEW -m tcp --dport 7022 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp -s trellis-front -m state --state NEW -m tcp --dport 7023 -j ACCEPT
#iptables -A INPUT -i eth0 -p tcp -s trellis-front -m state --state NEW -m tcp --dport 7024 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp -s trellis-front -m state --state NEW -m tcp --dport 7025 -j ACCEPT
#iptables -A INPUT -i eth0 -p tcp -s trellis-front -m state --state NEW -m tcp --dport 7026 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp -s trellis-front -m state --state NEW -m tcp --dport 7027 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp -s trellis-front -m state --state NEW -m tcp --dport 7028 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp -s trellis-front -m state --state NEW -m tcp --dport 7030 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp -s trellis-front -m state --state NEW -m tcp --dport 7031 -j ACCEPT
#iptables -A INPUT -i eth0 -p tcp -s trellis-front -m state --state NEW -m tcp --dport 8080 -j ACCEPT
iptables -A INPUT -p icmp -m state --state NEW -m icmp --icmp-type echo-request  -j ACCEPT

##
#  Default Input
#
iptables -A INPUT -j DROP

##
#  Default Output
#
#iptables -A OUTPUT -j DROP

##
#  Forwarding Constraints
#
iptables -A FORWARD -j DROP
