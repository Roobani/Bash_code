#!/bin/bash
#Checks root permission
if [ $(id -u) != "0" ]; then
   echo " "
   echo -e "\e[5mYou must be the superuser to run this script" >&2
   su -c "$0 $@"
#   echo " "
   exit 
fi

# Change this with output of <echo $DISPLAY> on server to start jconsole via connectbot android ssh app.
DISPLAY=":1000.0"

DIRECTORY=/var/www/vhosts/blueprintcleanse.com/subdomains/store/httpsdocs/
FILE=index.html
ALERT_MAIL=john@sodexis.com
divider=----------------------------------
divider=$divider
LOG=/var/app/compiere/Compiere2/utils/server.log

showmenu () {
    echo "Enter any one numeric number to proceed.."
    echo "1. Start the BPC compiere server"
    echo "2. Stop the BPC compiere server"
    echo "3. Restart the BPC compiere server"
    echo "4. Quit"
}

echo -e '\n'
echo "#############################################"
echo "#   Script to restart BPC compiere server  #"
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
export DISPLAY=$DISPLAY
jps="/usr/java/latest/bin/jps"
jconsole="/usr/java/latest/bin/jconsole"
pgrep -f jconsole &> /dev/null
if [ $? -eq 0 ]; then
        echo -e "The least running Jconsole instance are:" '\n'
        temp=$(ps ax | grep -v grep | grep jconsole)
        echo -e "$temp" '\n'
        echo -e "Sending KILL signal to all running jconsole instance" '\n'
        kill $(ps aux | grep '[j]console' | awk '{print $2}')
        echo -e "Starting Jconsole to Connect to Jboss AS" '\n'
        sleep 5
        pid=( $($jps -l | grep org.jboss.Main | cut -d ' ' -f 1) )
        $jconsole $pid &
        tem=$(ps ax | grep -v grep | grep jconsole)
        echo -e "$tem" '\n'
else
        echo -e "Starting Jconsole to Connect to Jboss AS" '\n'
        pid=( $($jps -l | grep org.jboss.Main | cut -d ' ' -f 1) )
        $jconsole $pid &
        tem=$(ps ax | grep -v grep | grep jconsole)
        echo -e "$tem" '\n'
fi
}

echo -e '\n'
while true ; do
    showmenu
    read -p "Enter your choice: " choices
    for choice in $choices ; do
        case "$choice" in
            1)
                echo -e '\n'
                echo "Starting the BPC compiere server"
                sleep 3
                read -p "Continue (y/n)?" char
                        case "$char" in 
                        y|Y ) 
                                export -f countdown
                                export -f strt
                                export -f stp
                                export -f progress
                                export -f jconso
                                export ALERT_MAIL
                                export divider
                                export LOG
                                export PLAY
                                echo -e '\n'
                                su compiere -c 'set -e && cd /var/app/compiere/Compiere2/utils && sleep 5 && echo " " && echo -e "\e[00;32mExecuting RUN_Server2.sh\e[00m" && echo -e "\e[00;32m$divider\e[00m" && echo " " && sleep 5 && ./RUN_Server2.sh > server.log && sed '\''/Started in/q'\'' < <(tail -n 0 -f $LOG) && sleep 15 && echo " " && strt && sleep 5 && jconso && sleep 10'
                                echo -e '\n'
                                cd $DIRECTORY
                                if fgrep -n -e '<link type="text/css" rel="stylesheet" href="https://sstore.blueprintcleanse.com/gwtstore/downpanel.css">' -e '<script type="text/javascript" language="javascript" src="https://sstore.blueprintcleanse.com/gwtstore/gwtstore.nocache.js">' index.html > out.txt; then
                                        cat out.txt
                                        rm -rf out.txt
                                        echo $divider
                                        echo "Line were renamed in $FILE"
                                        echo -e $divider '\n'
                                        sed -i -e 's_"https://sstore.blueprintcleanse.com/gwtstore/downpanel.css"_"https://store.blueprintcleanse.com/gwtstore/downpanel.css"_g' index.html
                                        sed -i -e 's_"https://sstore.blueprintcleanse.com/gwtstore/gwtstore.nocache.js"_"https://store.blueprintcleanse.com/gwtstore/gwtstore.nocache.js"_g' index.html
                                else
                                        echo "$FILE is OK"
                                        echo "SCRIPT EXITS"
                                        exit 1
                                fi
                        ;;

                        n|N ) exit 1
                        ;;
                        * ) echo "invalid"
                        ;;
                        esac
                ;;

                2)
                echo -e '\n'
                echo "Stopping the BPC compiere server"
                sleep 3
                read -p "Continue (y/n)?" char
                        case "$char" in 
                        y|Y ) 
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

                                if fgrep -n -e '<link type="text/css" rel="stylesheet" href="https://store.blueprintcleanse.com/gwtstore/downpanel.css">' -e '<script type="text/javascript" language="javascript" src="https://store.blueprintcleanse.com/gwtstore/gwtstore.nocache.js">' index.html > out.txt; then
                                        echo $divider
                                        echo "Line to change match in $FILE"
                                        echo -e $divider '\n'
                                        cat out.txt
                                        rm -rf out.txt
                                else
                                        echo "Line to change doesnt match in $FILE - Script Exits"
                                        exit 1
                                fi

                                # Replace the Lines contain store with sstore
                                sed -i -e 's_"https://store.blueprintcleanse.com/gwtstore/downpanel.css"_"https://sstore.blueprintcleanse.com/gwtstore/downpanel.css"_g' index.html
                                sed -i -e 's_"https://store.blueprintcleanse.com/gwtstore/gwtstore.nocache.js"_"https://sstore.blueprintcleanse.com/gwtstore/gwtstore.nocache.js"_g' index.html

                                echo -e '\n'

                                # Shows Lines modified or not with sstore.
                                if fgrep -n -e '<link type="text/css" rel="stylesheet" href="https://sstore.blueprintcleanse.com/gwtstore/downpanel.css">' -e '<script type="text/javascript" language="javascript" src="https://sstore.blueprintcleanse.com/gwtstore/gwtstore.nocache.js">' index.html > out.txt; then
                                        echo $divider
                                        echo "Lines are Modified with sstore in $FILE"
                                        echo -e $divider '\n'
                                        cat out.txt
                                        rm -rf out.txt
                                        echo " "
                                else
                                        echo "Lines doesnt modified in $FILE - Script Exits"
                                        exit 1
                                fi

                                export -f countdown
                                export -f strt
                                export -f stp
                                export -f progress
                                export -f jconso
                                export ALERT_MAIL
                                export divider
                                export LOG
                                export PLAY
                                echo -e '\n'

                                su compiere -c 'set -e && cd /var/app/compiere/Compiere2/utils && sleep 5 && echo " " && countdown 900 && echo -e "\e[00;32mExecuting RUN_Server2Stop.sh\e[00m" && echo -e "\e[00;32m$divider\e[00m" && ./RUN_Server2Stop.sh && echo " " && progress 40 && stp && sleep 5 && mv server.log server$(date +%Y-%m-%d_%R).log && echo server.log renamed to server$(date +%Y-%m-%d_%R).log'
                        ;;

                        n|N ) exit 1
                        ;;
                        * ) echo "invalid"
                        ;;
                        esac
                ;;

                3)
                echo -e '\n'
                echo "Restarting the BPC compiere server"
                sleep 3
                read -p "Continue (y/n)?" char
                        case "$char" in 
                        y|Y )
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
                                if fgrep -n -e '<link type="text/css" rel="stylesheet" href="https://store.blueprintcleanse.com/gwtstore/downpanel.css">' -e '<script type="text/javascript" language="javascript" src="https://store.blueprintcleanse.com/gwtstore/gwtstore.nocache.js">' index.html > out.txt; then
                                   echo $divider
                                   echo "Line to change match in $FILE"
                                   echo -e $divider '\n'
                                   cat out.txt
                                   rm -rf out.txt
                                else
                                   echo "Line to change doesnt match in $FILE - Script Exits"
                                   exit 1
                                fi

                                # Replace the Lines contain store with sstore
                                sed -i -e 's_"https://store.blueprintcleanse.com/gwtstore/downpanel.css"_"https://sstore.blueprintcleanse.com/gwtstore/downpanel.css"_g' index.html
                                sed -i -e 's_"https://store.blueprintcleanse.com/gwtstore/gwtstore.nocache.js"_"https://sstore.blueprintcleanse.com/gwtstore/gwtstore.nocache.js"_g' index.html

                                echo -e '\n'

                                # Shows Lines modified or not with sstore.
                                if fgrep -n -e '<link type="text/css" rel="stylesheet" href="https://sstore.blueprintcleanse.com/gwtstore/downpanel.css">' -e '<script type="text/javascript" language="javascript" src="https://sstore.blueprintcleanse.com/gwtstore/gwtstore.nocache.js">' index.html > out.txt; then
                                   echo $divider
                                   echo "Lines are Modified with sstore in $FILE"
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
                                export PLAY

                                su compiere -c 'set -e && cd /var/app/compiere/Compiere2/utils && sleep 5 && echo " " && countdown 900 && echo -e "\e[00;32mExecuting RUN_Server2Stop.sh\e[00m" && echo -e "\e[00;32m$divider\e[00m" && ./RUN_Server2Stop.sh && echo " " && progress 40 && stp && sleep 5 && mv server.log server$(date +%Y-%m-%d_%R).log && echo server.log renamed to server$(date +%Y-%m-%d_%R).log && countdown 180 && echo -e "\e[00;32mExecuting RUN_Server2.sh\e[00m" && echo -e "\e[00;32m$divider\e[00m" && echo " " && sleep 5 && ./RUN_Server2.sh > server.log && sed '\''/Started in/q'\'' < <(tail -n 0 -f $LOG) && sleep 15 && echo " " && strt && sleep 5 && jconso && sleep 10'

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
                        ;;

                        n|N ) exit 1
                        ;;
                        * ) echo "invalid"
                        ;;
                        esac
                ;;

                4) echo "Script Exits"
                        exit 1
                ;;
        esac
        done
done
exit 0
