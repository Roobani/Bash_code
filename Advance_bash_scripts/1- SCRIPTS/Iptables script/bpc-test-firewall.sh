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

#Force SYN packets check
iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
#Force Fragments packets check
iptables -A INPUT -f -j DROP
#XMAS packets
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
#Drop all NULL packets
iptables -A INPIT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -m state --state INVALID -j DROP

iptables -A OUTPUT -p tcp ! --syn -j REJECT --reject-with tcp-reset
iptables -A OUTPUT -m state --state INVALID -j DROP

iptables -A FORWARD -p tcp ! --syn -j REJECT --reject-with tcp-reset
iptables -A FORWARD -m state --state INVALID -j DROP

#Allow unlimited traffic on the loopback interface
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A FORWARD -i lo -o lo -j ACCEPT

#Plesk ADminstrative interface accessable from server. (localhost:8443-https)
# No need i think "lo" will take care for localhost.
#iptables -A INPUT -i eth0 -p tcp --dport 8443 -m state --state ESTABLISED -j ACCEPT
#iptables -A OUTPUT -o eth0 -p tcp --sport 8443 -m state --state NEW,ESTABLISHED -j ACCEPT

#WWW incoming
iptables -A INPUT -i eth0 -p tcp --dport 80 -m state --state NEW,ESTABLISED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT

#WWW output New connection for yum update to work
iptables -A OUTPUT -o eth0 -p tcp --dport 80 -m state --state NEW -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --sport 80 -m state --state NEW,ESTABLISED -j ACCEPT

#https
iptables -A INPUT -i eth0 -p tcp --dport 443 -m state --state NEW,ESTABLISED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT

#SSH server
iptables -A INPUT -i eth0 -p tcp --dport 2298 -m state --state NEW,ESTABLISED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --sport 2298 -m state --state ESTABLISHED -j ACCEPT

#Domain Name Server:DNS servers listen on port 53 for queries from DNS clients. In this i need to open remote port 53 from any localport.
iptables -A OUTPUT -o eth0 -p udp -s 50.21.181.61/32 --sport 1024:65535 -d 0/0 --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -i eth0 -p udp -s 0/0 --sport 53 -d 50.21.181.61/32 --dport 1024:65535 -m state --state ESTABLISHED -j ACCEPT

#Network Time Protocol (NTP) - used for time synchronization. In this i need to open remote port 123 from any localport.
iptables -A OUTPUT -o eth0 -p udp -s 50.21.181.61/32 --sport 1024:65535 -d 0/0 --dport 123 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -i eth0 -p udp -s 0/0 --sport 123 -d 50.21.181.61/32 --dport 1024:65535 -m state --state ESTABLISHED -j ACCEPT

#NagiosXI, server 74.xxx queries the NRPE to server 
iptables -A INPUT -i eth0 -p tcp -s 74.208.98.95/32 --sport 1024:65535 -d 50.21.181.61/32 --dport 5666 -m state --state NEW,ESTABLISED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp -s 50.21.181.61/32 --sport 5666 -d 74.208.98.95/32 --dport 1024:65535 -m state --state ESTABLISHED -j ACCEPT

#NagiosXI SNMP
iptables -A INPUT -i eth0 -p tcp -s 74.208.98.95/32 --sport 1024:65535 -d 0/0 --dport 161 -m state --state NEW,ESTABLISED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp 50.21.181.61/32 --sport 161 -d 74.208.98.95/32 --dport 1024:65535 -m state --state ESTABLISHED -j ACCEPT

#Ping Service
iptables -A INPUT -p icmp -s 117.0.0.0/8 --icmp-type 8/0 -j ACCEPT

#logging
iptables -N LOGGING
iptables -A INPUT -j LOGGING
iptables -A LOGGING -m limit --limit 2/min -j LOG --log-prefix "IPTables-Dropped: " --log-level 4
iptables -A LOGGING -j DROP

#Save settings
/sbin/service iptables save

#List rules
iptables -L -v

# End of script