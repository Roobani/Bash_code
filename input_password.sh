#!/bin/bash

GREEN="32"
BOLDGREEN="\e[1;${GREEN}m"
RED='\033[1;31m'
BLUE='\033[1;34m'

###########################################################

echo
echo
echo -e "${BOLDGREEN}         Please Enter username   "
read username
echo
#echo -e $username
#echo $read
echo -e "${RED}            Enter password        "
echo
read -s password
echo
echo
if  [[ ( $username == "harmony" && $password == "harmony") ]]; then
figlet "Vanakkam da Maapala"
else
echo
#figlet "Pls GET OUT"  #| cowsay
cowsay Pls GET OUT
echo
echo
fi
echo

