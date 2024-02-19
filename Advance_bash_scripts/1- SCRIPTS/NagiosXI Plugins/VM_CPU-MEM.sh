#!/bin/bash
top=$(which top)
CPU=`$top -b -p $(pgrep -d',' vmware-vmx) -n 1 | awk 'NR>7 { sum += $9; } END { print sum; }'`
MEM=`$top -b -p $(pgrep -d',' vmware-vmx) -n 1 | awk 'NR>7 { sum += $10; } END { print sum; }'`
PROC=`$top -b -p $(pgrep -d',' vmware-vmx) -n 1 | awk 'NR>7 { if ($1) count++ } END { print count; }'`


(pgrep -d',' -f /opt/odoo-11/conf/odoo.conf).. the  The -f flag in pgrep makes it match the command line instead of program name.

echo CPU: $CPU
echo MEM: $MEM
echo PROC: $PROC

exit 1


top -b -u admin -n 1 | awk 'NR>7 { sum += $9; } END { print sum; }'
top -b -u admin -n 1 | awk 'NR>7 { sum += $10; } END { print sum; }'




echo Cpu: "$(top -b -n 1 | awk 'NR>7 { sum += $9; } END { print sum; }')" >>/tmp/Nagios-OpenerpTest_VM



top -b -p $(pgrep -f openerp-server.conf) -n 1 | awk 'NR>7 { sum += $9; } END { print sum; }'

top -bn1 | grep -E 'openerp-server.conf' | awk 'NR>7 { sum += $9; } END { print sum; }'


top -c -bn1 |grep -v grep| grep odoo.conf | awk '{ sum += $5; } END { print sum; }'

top -c -bn1 |grep -v grep| grep openerp-server.conf | awk '{ sum += $6; } END { print sum; }'

top -p`ps -ef | grep -i openerp-server.conf | grep -v grep | gawk '{print $2}'`





accuratly find the process memroy usage:

grep Pss: /proc/[pid]/smaps | awk '{ sum+=$4; } END{ print sum; }'
top


top -bn1 | grep -E 'openerp-sciencefirst.conf' | awk 'NR>7 { sum += $9; } END { print sum; }'
top -c -bn1 |grep -v grep| grep openerp-sciencefirst.conf | awk '{ sum += $5; } END { print sum; }'


top -p`ps -ef | grep -i openerp-sciencefirst.conf