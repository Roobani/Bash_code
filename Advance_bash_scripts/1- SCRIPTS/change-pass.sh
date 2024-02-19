#!/bin/bash

#Prerequisties : 

# In /etc/ssh/sshd_config:
#   PermitRootLogin without-password
#	AllowUsers root
#       Add the tools VM public key to the /root/.ssh/authorized_keys
#       Make sure .ssh has 700  and authorized_keys has 600

# cd /root && touch ~/.hushlogin && if [ ! -d "/root/.ssh" ]; then mkdir .ssh; fi && chmod 700 .ssh && cd .ssh && echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCjvPYPS4js9FGW880qtGOpQ0vim0K3sDFCqTAh996EqGuNhaUHu+RxLdfupzRydUpPznrhkaCZh5CAYZ+MwlczCbFGaNcysh3j8wNIfLmGS1O2DVedMyJZocNU8p1Y3V/qpmAYrzQvZvzevwovU00EFXcvAo5/4amuRwkLX41r7UOVkcH6C+mxzxsB5gIlbliYcPjHVA3Tp7Vl8ruQzpA1ATUJV5peusY881SuWnTYooIpIYvj24+5WvlWVzJID7cYuQjHlthrj8ElTA0Whb9PsHybT/IJHCTZjoqG8rJw3PeYIpQzEdZL2ulC+ArZKuFn551UJ67PFevuZrqqNDjv root@proxmox" >> authorized_keys && chmod 600 authorized_keys && sed -i '/^AllowUsers/ s/$/ root/' /etc/ssh/sshd_config  && systemctl restart ssh

# && sed -i 's/.*PermitRootLogin.*/PermitRootLogin without-password/' /etc/ssh/sshd_config 

N=8
TARGET_USER=sodexis
NEWPASS='U7bW866%^GelY#ZX*sU4'

server1=( 'HEN PRO' '192.99.182.92' 'root' '4010' 'F22V%q7ACKmb&dT3jjCQ' )
server2=( 'SOD PRO' '192.99.182.92' 'root' '4011' '&a$bCPg3mloqHa8&0WI0' )
server3=( 'CAU PRO' '192.99.182.92' 'root' '4012' 'r06AZ#KLMbFo4he9F^uA' )
server4=( 'SOH PRO' '192.99.182.92' 'root' '4013' 'YlTnXNlnP12Q%lnXl3vo' )
server5=( 'LS PRO' '192.99.182.92' 'root' '4015' '9I0Ygy6FtULq@@UxsrI&' )
server6=( '32S PRO' '192.99.182.92' 'root' '4016' )
server7=( 'KG PRO' '192.99.182.92' 'root' '4017' )
server8=( 'LAS PRO' '192.99.182.92' 'root' '4018' )
server9=( 'ETS PRO' '142.44.139.161' 'root' '2259' )
server10=( 'MAT PRO' '209.16.138.29' 'root' '2258' )
#server11=( 'NCCRC PRO' '68.233.218.190' 'root' '2295' )

for ((i = 1; i <= N; i++)); do
#Check for commented server.
tmp_serv=server${i}
serv=("${!tmp_serv}")
if [ ! -z "${serv}" ]; then
	tmp_array_name="server$i[@]"
    tmp_array=("${!tmp_array_name}")
    echo ""
    echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
    echo "Checking for ${tmp_array[0]} SSH login..."
	ssh -p ${tmp_array[3]} -o BatchMode=yes ${tmp_array[2]}@${tmp_array[1]} 'exit'
	if [ $? -eq 1 ]; then
        echo " "
        echo "SSH login failed. Scripts Aborting!"
	exit 1
	fi
	echo "Login Passed"
	echo " "
ssh -p ${tmp_array[3]} -q -o 'BatchMode=yes' ${tmp_array[2]}@${tmp_array[1]} /bin/bash <<END
echo -e "${NEWPASS}\n${NEWPASS}" | passwd ${TARGET_USER}
END
fi
done
