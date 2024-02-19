#!/bin/bash

set -e 

#Turn off IP Forwarding
#echo 0 > /proc/sys/net/ipv4/ip_forward

#setting default policy to accept before flushing the rules. This could prevent locking ourself out if we connecting remotely to server via SSH.
iptables -P INPUT ACCEPT

#Remove any existing rules from all chains
iptables -F
iptables -X

#Zero counts
iptables -Z

# Set Policies
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

iptables -A INPUT -p tcp ! --syn -j REJECT --reject-with tcp-reset
iptables -A INPUT -m state --state INVALID -j DROP

iptables -A OUTPUT -p tcp ! --syn -j REJECT --reject-with tcp-reset
iptables -A OUTPUT -m state --state INVALID -j DROP

iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -p tcp ! --syn -j REJECT --reject-with tcp-reset
iptables -A FORWARD -m state --state INVALID -j DROP

#Allow unlimited traffic on the loopback interface
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A FORWARD -i lo -o lo -j ACCEPT

#Plesk ADminstrative interface (8443:https)

iptables -A INPUT -i eth0 -p tcp --dport 8443 -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --sport 8443 -m state --state NEW,ESTABLISHED -j ACCEPT

#WWW server
iptables -A INPUT -i eth0 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT

iptables -A INPUT -i eth0 -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT

#SSH server
iptables -A INPUT -i eth0 -p tcp --dport 2298 -m state --state NEW,ESTABLISED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --sport 2298 -m state --state ESTABLISHED -j ACCEPT

#Domain Name Server:DNS servers listen on port 53 for queries from DNS clients.
iptables -A OUTPUT -o eth0 -p udp --sport 1024:65535 --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -i eth0 -p udp --sport 53 --dport 1024:65535 -m state --state ESTABLISHED -j ACCEPT

#Network Time Protocol (NTP) - used for time synchronization
iptables -A OUTPUT -o eth0 -p udp --sport 1024:65535 --dport 123 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -i eth0 -p udp --sport 123 --dport 1024:65535 -m state --state ESTABLISHED -j ACCEPT

#NagiosXI
iptables -A INPUT -i eth0 -p tcp -s 74.208.98.95/32 --dport 5666 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --sport 5666 -m state --state ESTABLISHED -j ACCEPT

#NagiosXI SNMP
iptables -A INPUT -i eth0 -p tcp -s 74.208.98.95/32 --dport 161 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --sport 161 -m state --state ESTABLISHED -j ACCEPT

#Ping Service
iptables -A INPUT -p icmp --icmp-type 8/0 -j ACCEPT

# To permit machines internal to the network to be able to send IP packets to the outside world: 1 = Enable
#echo 1 > /proc/sys/net/ipv4/ip_forward

#Save settings
/sbin/service iptables save

#List rules
iptables -L -v

# End of script