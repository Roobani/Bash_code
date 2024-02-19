#!/bin/bash

# Log.io stop start script.
# Author: John, Sodexis
# This script is located in proxmox server /opt/support_files/scripts/log-io-pro-restart.sh
# Add the replication proxmox root user id_rsa.pub key to the production server sodexis user .ssh/authorized_keys  and add the sudoers entry as
# sodexis ALL=(ALL) NOPASSWD: /bin/systemctl restart log.h
#
# Append new server below with the exact format.  '<hostname>' '<IP>' '<Login User>' '<SSH port>'
# Make sure the client has the public key of the log.io-server such that log.io-server can login without password.
# Encase if you dont want any server, then just put # in front of it. this script will exclude that.
# NOTE: Make user you add touch ~/.hushlogin  on target machine to suppress the ssh banner.

N=10
server1=( 'HEN PRO' '192.99.182.92' 'root' '4010' )
server2=( 'SOD PRO' '192.99.182.92' 'root' '4011' )
server3=( 'CAU PRO' '192.99.182.92' 'root' '4012' )
server4=( 'SOH PRO' '192.99.182.92' 'root' '4013' )
server5=( 'LS PRO' '192.99.182.92' 'root' '4015' )
server6=( '32Sport PRO' '192.99.182.92' 'root' '4016' )
server7=( 'KG PRO' '192.99.182.92' 'root' '4017' )
server8=( 'LAS PRO' '192.99.182.92' 'root' '4018' )
server9=( 'ETS PRO' '142.44.139.161' 'root' '2259' )
server10=( 'MAT PRO' '209.16.138.29' 'root' '2258' )



#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ STOPPING OF LOG.IO HARVESTER @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

for ((i = 1; i <= N; i++)); do
#Check for commented server.
tmp_serv=server${i}
serv=("${!tmp_serv}")
if [ ! -z "${serv}" ]; then
	tmp_array_name="server$i[@]"
    tmp_array=("${!tmp_array_name}")
    echo "Checking for ${tmp_array[0]} SSH login..."
	ssh -p ${tmp_array[3]} -o BatchMode=yes ${tmp_array[2]}@${tmp_array[1]} 'exit'
	if [ $? -eq 1 ]; then
        echo " "
        echo "SSH login failed. Scripts Aborting!"
	exit 1
	fi
	echo "Login Passed"
	echo " "
	echo "Restarting log.io harvester in ${tmp_array[0]}...."
    export tmp_array=("${!tmp_array_name}")
ssh -p ${tmp_array[3]} -q ${tmp_array[2]}@${tmp_array[1]} << 'ENDSSH1'
echo " "
user=$(whoami)
host=$(hostname)
echo Logged-in $user@$host
echo " "
systemctl restart log.h

ENDSSH1
fi
done

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

exit 0