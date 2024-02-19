#!/bin/bash
#Checks root permission
if [ $(id -u) != "0" ]; then
   echo " "
   echo -e "\e[5mYou must be the superuser to run this script" >&2
   su -c "$0 $@"
#   echo " "
   exit 
fi

DIRECTORY=/var/www/vhosts/blueprintcleanse.com/subdomains/teststore/httpsdocs/
FILE=index.html
ALERT_MAIL=john@sodexis.com
divider=----------------------------------
divider=$divider
LOG=/var/app/compiere/Compiere2/utils/server.log

echo -e '\n'
echo "#############################################"
echo "#   Script to restart test compiere server  #"
echo "#############################################"
echo -e '\n'
sleep 5

function countdown()
{ 
      local SECONDS=$1
      local START=$(date +%s)
      local END=$((START + SECONDS))
      local CUR=$START
      echo " "
      echo -e  "\e[00;31m Time Remaining to proceed\e[00m"
      echo -e  "\e[00;31m---------------------------\e[00m"
      while [[ $CUR -lt $END ]]
        do
            CUR=$(date +%s)
            LEFT=$((END-CUR))
            printf "\r%02d:%02d:%02d" \ $((LEFT/3600)) $(( (LEFT/60)%60)) $((LEFT%60))
            sleep 1
        done
      echo -e '\n'
}

function strt ()
{
    pgrep -f jboss &> /dev/null
    if [ $? -eq 0 ]; then
       echo " "
       echo -e "\e[00;32m$divider\e[00m"
       echo -e "\e[00;32mJboss started\e[00m"
       echo -e "\e[00;32m$divider\e[00m" '\n'
    else
       echo $divider
       echo "jboss not started - Script Exists"
       echo "Script executed RUN_Server2Stop.sh but jboss is still running" | mail -s autostart.sh_problem $ALERT_MAIL
       echo -e "Alert Mail Sent to:""\033[4m$ALERT_MAIL\033[0m"
       echo -e $divider '\n'
       exit 1 
    fi
}

function stp ()
{
    pgrep -f jboss &> /dev/null
    if [ $? -eq 1 ]; then
       echo -e "\e[00;31m$divider\e[00m"
       echo -e "\e[00;31mjboss stopped\e[00m"
       echo -e "\e[00;31m$divider\e[00m"
    else
       echo $divider
       echo -e "\e[00;32mJboss not stopped and is still running\e[00m"
        echo $divider
       echo "Script executed RUN_Server2Stop.sh but jboss is still running" | mail -s autostart.sh_problem $ALERT_MAIL
       echo -e "Alert Mail sent to:""\033[4m$ALERT_MAIL\033[0m"
    exit 1
    fi
}

function progress(){
      local SECONDS=$1
      local START=1
      local CUR=$START
      local END=$SECONDS
 echo -n "Please wait..."
while [[ $CUR -lt $END ]]
  do
        CUR=$[$CUR+1]
    echo -n "."
    sleep 3
  done
echo -n "...done."
echo
}

function jconso(){
    pgrep -f jconsole &> /dev/null
if [ $? -eq 0 ]; then
echo -e "The least running Jconsole instance are:" '\n'
temp=$(ps ax | grep -v grep | grep jconsole)
echo -e "$temp" '\n'
echo -e "Sending KILL signal to all running jconsole instance" '\n'
#pid=( $(jps -l | grep sun.tools.jconsole.JConsole | grep -v grep | awk '{print $1}') )
#for pid in "${pid[@]}"; do
#echo -e $pid '\n'
#kill $pid
#done
#ps ax | grep jconsole | grep -v grep | cut -d ' ' -f 1 | xargs -rn1 kill
kill $(ps aux | grep '[j]console' | awk '{print $2}')
echo -e "Starting Jconsole to Connect to Jboss AS" '\n'
sleep 5
pid=( $(jps -l | grep org.jboss.Main | cut -d ' ' -f 1) )
jconsole $pid &
tem=$(ps ax | grep -v grep | grep jconsole)
echo -e "$tem" '\n'
else
echo -e "Starting Jconsole to Connect to Jboss AS" '\n'
pid=( $(jps -l | grep org.jboss.Main | cut -d ' ' -f 1) )
jconsole $pid &
tem=$(ps ax | grep -v grep | grep jconsole)
echo -e "$tem" '\n'
fi
}

#Checks index file Exist or Not
cd $DIRECTORY
     if [ -f $FILE ]; then
    
       echo "File $FILE exists"
       ls -ld $FILE
       sleep 3
       echo " "
       cp index.html index.html_save
       if [ -f index.html_save ]; then
          echo "File copied Successfully"
          ls -ld index.html_save
          
       else
       echo "File $FILE does not exists" 1>&2
       exit 1
     fi
   fi

echo -e '\n'
sleep 3

#Checks whether Lines to change exists or Not
if fgrep -n -e '<link type="text/css" rel="stylesheet" href="https://teststore.blueprintcleanse.com/gwtstore/downpanel.css">' -e '<script type="text/javascript" language="javascript" src="https://teststore.blueprintcleanse.com/gwtstore/gwtstore.nocache.js">' index.html > out.txt; then
   echo $divider
   echo "Line to change match in $FILE"
   echo -e $divider '\n'
   cat out.txt
   rm -rf out.txt
else
   echo "Line to change doesnt match in $FILE - Script Exits"
   exit 1
fi

# Replace the Lines contain teststore with testsstore
sed -i -e 's_"https://teststore.blueprintcleanse.com/gwtstore/downpanel.css"_"https://testsstore.blueprintcleanse.com/gwtstore/downpanel.css"_g' index.html
sed -i -e 's_"https://teststore.blueprintcleanse.com/gwtstore/gwtstore.nocache.js"_"https://testsstore.blueprintcleanse.com/gwtstore/gwtstore.nocache.js"_g' index.html

echo -e '\n'

# Shows Lines modified or not with testsstore.
if fgrep -n -e '<link type="text/css" rel="stylesheet" href="https://testsstore.blueprintcleanse.com/gwtstore/downpanel.css">' -e '<script type="text/javascript" language="javascript" src="https://testsstore.blueprintcleanse.com/gwtstore/gwtstore.nocache.js">' index.html > out.txt; then
   echo $divider
   echo "Lines are Modified with testsstore in $FILE"
   echo -e $divider '\n'
   cat out.txt
   rm -rf out.txt
   echo " "
else
   echo "Lines doesnt modified in $FILE - Script Exits"
   exit 1
fi

#Export the function to make it available to the compiere user's subshell
export -f countdown
export -f strt
export -f stp
export -f progress
export -f jconso
export ALERT_MAIL
export divider
export LOG

su compiere -c 'set -e && cd /var/app/compiere/Compiere2/utils && sleep 5 && echo " " && countdown 180 && echo -e "\e[00;32mExecuting RUN_Server2Stop.sh\e[00m" && echo -e "\e[00;32m$divider\e[00m" && ./RUN_Server2Stop.sh && echo " " && progress 20 && stp && sleep 5 && mv server.log server$(date +%Y-%m-%d_%R).log && echo server.log renamed to server$(date +%Y-%m-%d_%R).log && countdown 60 && echo -e "\e[00;32mExecuting RUN_Server2.sh\e[00m" && echo -e "\e[00;32m$divider\e[00m" && echo " " && sleep 5 && ./RUN_Server2.sh > server.log && sed '\''/Started in/q'\'' < <(tail -n 0 -f $LOG) && sleep 15 && echo " " && strt && sleep 5 && jconso && sleep 3'

if [ $? -eq 0 ];then
   sleep 5
   echo "======================================="
   echo "Compiere Server restarted successfully"
   echo "======================================="
   echo -e '\n'
   sleep 5
   echo "Proceeding to change $FILE"
   sleep 5

   cp index.html_save index.html
   echo " "
   echo "index.html copied"
   echo " "
   echo "SCRIPT EXITS"
else
   echo "Script stopped with error code $?"
   echo "Script stopped with error. Store remain closed" | mail -s autostart.sh_problem $ALERT_MAIL
   echo -e "Alert Mail sent to:""\033[4m$ALERT_MAIL\033[0m"
   exit 1
fi
exit
