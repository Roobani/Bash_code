#!/bin/bash
set -x
SRVDNS=`grep -m1 ^nameserver /etc/resolv.conf | awk '{print $2}'`
PFXDNS=`grep -m1 ^nameserver /var/spool/postfix/etc/resolv.conf | awk '{print $2}'`

if [ "$SRVDNS" != "$PFXDNS" ]; then
MQB=`mailq | grep -c "^[A-F0-9]"`
/usr/sbin/service postfix restart
/usr/sbin/postqueue -f
sleep 1800
MQB=$(/usr/bin/mailq | grep -c "^[A-F0-9]")
PFXDNS1=`grep -m1 ^nameserver /var/spool/postfix/etc/resolv.conf | awk '{print $2}'`
echo -e "DNS-PROXY Container IP changed.\nOLD POSTFIX DNS IP=${PFXDNS}\nNEW DNS IP=${SRVDNS}\nCURRENT POSTFIX DNS IP=${PFXDNS1}\nMAIL QUEUE BEFORE RESTART=${MQB}\nRestarted postfix in testserver.sodexis.com\nMAIL QUEUE AFTER RESTART=${MQ}" | mail -s "Testserv DNS-PROXY IP Update" john@sodexis.com
fi

