#!/bin/bash
SCRIPT_NAME=`basename $0`
OPENERP_PATH="/opt/openerp/v7.0/"
SODEXISMODULES_PATH="/opt/openerp/sodexismodules/"
SCIENCEFIRST_PATH="/opt/openerp/sciencefirst/sciencefirst/"
SODEXIS_PATH="/opt/openerp/sodexis/sodexis/"
SVN="$(which svn)"
MAIL="$(which mailx)"
A_EMAIL=john@sodexis.com
CC1=skeller@sodexis.com
OPENERPSVN_LOG="/opt/scripts/logs/openerpsvn_update.log"
SODEXISMODSVN_LOG="/opt/scripts/logs/sodexismodules_update.log"
SCIENCESVN_LOG="/opt/scripts/logs/sciencefirst_update.log"
SODEXISSVN_LOG="/opt/scripts/logs/sodexis_update.log"
USER="stephan"
PASS="step1234"
CRON="$(which crontab)"

if [ $(id -u) != "1001" ]; then
    echo " "
    echo "This Script must be executed by sodexis user" 1>&2
    exit 1
fi

T1=$(crontab -l | grep -i "$SCRIPT_NAME" | cut -c -1)
#Below if condition checks whether cronjob already got commented by this scipt. This is to enable it, if run manually.
if [ "$T1" == "#" ]; then
    crontab -l | sed "/^#.*$SCRIPT_NAME/s/^#//" | crontab -
fi


function openerpfn ()
{
cd $OPENERP_PATH
echo $(date) > $OPENERPSVN_LOG
$SVN update --username $USER --password $PASS --non-interactive --no-auth-cache >> $OPENERPSVN_LOG 2>&1

if grep -oq 'locked' $OPENERPSVN_LOG; then
	cd $OPENERP_PATH
	echo $(date) > $OPENERPSVN_LOG
	$SVN cleanup
	sleep 10
	$SVN update --username $USER --password $PASS --non-interactive --no-auth-cache >> $OPENERPSVN_LOG 2>&1
	if grep -oq 'locked' $OPENERPSVN_LOG; then
		#Disable the crontab if the lock doesn't cleared by some other issue.
		crontab -l | sed "/^[^#].*$SCRIPT_NAME/s/^/#/" | crontab -
		echo " " >> $OPENERPSVN_LOG
    	echo "Note: Working copy v7.0 is locked. svn cleanup failed. cronjob is stopped. resolve and run the /opt/scripts/$SCRIPT_NAME script manually again by script user." >> $OPENERPSVN_LOG       
    	$MAIL -s "FAILURE - OpenerpTest [v7.0] svn udpate" -c "$CC1" "$A_EMAIL" < $OPENERPSVN_LOG
    	exit 1
	fi
elif grep -oq 'Could not resolve hostname' $OPENERPSVN_LOG; then
	cd $OPENERP_PATH
	echo $(date) > $OPENERPSVN_LOG
	#Disabled the 5 min cronjob such that for-loop check 5 times = 25 min 
    crontab -l | sed "/^[^#].*$SCRIPT_NAME/s/^/#/" | crontab - 
    SEND_EMAIL=true
    for (( c=1; c<=5; c++ ))
    do
        echo $(date) > $OPENERPSVN_LOG
        $SVN update --username $USER --password $PASS --non-interactive --no-auth-cache >> $OPENERPSVN_LOG 2>&1
        OT=$(grep -o 'At revision\|Updated to revision' $OPENERPSVN_LOG)
        if [ -z "$OT" ]; then                          
            sleep 300
         else
            #Enable the cronjob if variable OT returns non-empty     
            crontab -l | sed "/^#.*$SCRIPT_NAME/s/^#//" | crontab -
            SEND_EMAIL=false  
            break
         fi
    done
    if $SEND_EMAIL; then
    	echo "Note: Working copy v7.0 could not resolve hostname. cronjob is stopped. resolve and run the /opt/scripts/$SCRIPT_NAME script manually again by script user." >> $OPENERPSVN_LOG       
    	$MAIL -s "FAILURE - OpenerpTest [v7.0] svn udpate" -c "$CC1" "$A_EMAIL" < $OPENERPSVN_LOG
    	exit 1
    fi
elif ! grep -oq 'At revision\|Updated to revision' $OPENERPSVN_LOG; then       
    #Disabled the 5 min cronjob such that for-loop check 5 times = 25 min 
    crontab -l | sed "/^[^#].*$SCRIPT_NAME/s/^/#/" | crontab - 
    for (( c=1; c<=5; c++ ))
    do
         echo $(date) > $OPENERPSVN_LOG
         $SVN update --username $USER --password $PASS --non-interactive --no-auth-cache >> $OPENERPSVN_LOG 2>&1
         OT=$(grep -o 'At revision\|Updated to revision' $OPENERPSVN_LOG)
         if [ -z "$OT" ]; then                          
            sleep 300
         else
            #Enable the cronjob if variable OT returns non-empty     
            crontab -l | sed "/^#.*$SCRIPT_NAME/s/^#//" | crontab -  
            break
         fi
    done
fi
#Below will execute once for-loop completel 5 cycle.
if [ -z "$OT" ]; then   
    echo " " >> $OPENERPSVN_LOG
    echo "Note: Error occured with v7.0 repo update. cronjob is stopped. resolve and run the /opt/scripts/$SCRIPT_NAME script manually again by script user." >> $OPENERPSVN_LOG       
    $MAIL -s "FAILURE - OpenerpTest [v7.0] svn udpate" -c "$CC1" "$A_EMAIL" < $OPENERPSVN_LOG
fi
}


function sodexismodulesfn ()
{
cd $SODEXISMODULES_PATH
echo $(date) > $SODEXISMODSVN_LOG
$SVN update --username $USER --password $PASS --non-interactive --no-auth-cache >> $SODEXISMODSVN_LOG 2>&1
OT=$(grep -o 'At revision\|Updated to revision' $SODEXISMODSVN_LOG)        
if [ -z "$OT" ]; then
    #Disabled the 5 min cronjob such that for-loop check 5 times = 25 min 
    crontab -l | sed "/^[^#].*$SCRIPT_NAME/s/^/#/" | crontab - 
    for (( c=1; c<=5; c++ ))
    do
         echo $(date) > $SODEXISMODSVN_LOG
         $SVN update --username $USER --password $PASS --non-interactive --no-auth-cache >> $SODEXISMODSVN_LOG 2>&1
         OT=$(grep -o 'At revision\|Updated to revision' $SODEXISMODSVN_LOG)
         if [ -z "$OT" ]; then
               sleep 300
         else
               #Enable the cronjob if variable OT returns non-empty
               crontab -l | sed "/^#.*$SCRIPT_NAME/s/^#//" | crontab -
               break
         fi
    done
fi
#Below will execute once for-loop completel 5 cycle.
if [ -z "$OT" ]; then
    echo " " >> $SODEXISMODSVN_LOG
    echo "Note: Error occured with sodexismodules repo update. cronjob is stopped. resolve and run the /opt/scripts/$SCRIPT_NAME script manually again by script user." >> $SODEXISMODSVN_LOG       
    $MAIL -s "FAILURE - OpenerpTest [sodexismodules] svn udpate" -c "$CC1" "$A_EMAIL" < $SODEXISMODSVN_LOG
fi
}


function sciencefirstfn ()
{
cd $SCIENCEFIRST_PATH
echo $(date) > $SCIENCESVN_LOG
$SVN update --username $USER --password $PASS --non-interactive --no-auth-cache >> $SCIENCESVN_LOG 2>&1
ST=$(grep -o 'At revision\|Updated to revision' $SCIENCESVN_LOG)
if [ -z "$ST" ]; then
    T=$(crontab -l | grep -i "$SCRIPT_NAME" | cut -c -1)
        #Below if condition checks whether cronjob already got commented by openerpsvn funtion. If Not, then comment it.
        if [ "$T" != "#" ]; then
             #Disabled the 5 min cronjob such that for-loop check 5 times = 25 min 
             crontab -l | sed "/^[^#].*$SCRIPT_NAME/s/^/#/" | crontab -
        fi
    for (( c=1; c<=5; c++ ))
    do
         echo $(date) > $SCIENCESVN_LOG
         $SVN update --username $USER --password $PASS --non-interactive --no-auth-cache >> $SCIENCESVN_LOG 2>&1
         ST=$(grep -o 'At revision\|Updated to revision' $SCIENCESVN_LOG)
         if [ -z "$ST" ]; then
               sleep 300
         else
               #Enables the cronjob if variable OT returns non-empty within 5 cycle     
               crontab -l | sed "/^#.*$SCRIPT_NAME/s/^#//" | crontab - 
               break
         fi
    done
fi 
if [ -z "$ST" ]; then   
    echo " " >> $SCIENCESVN_LOG
    echo "Note: Error occured with sciencefirst repo update. cronjob is stopped. resolve and run the /opt/scripts/$SCRIPT_NAME script manually again by script user." >> $SCIENCESVN_LOG                       
    $MAIL -s "FAILURE - Test server Sciencefirst udpate" -c "$CC1" "$A_EMAIL" < $SCIENCESVN_LOG 
fi
}

function sodexisfn ()
{
cd $SODEXIS_PATH
echo $(date) > $SODEXISSVN_LOG
$SVN update --username $USER --password $PASS --non-interactive --no-auth-cache >> $SODEXISSVN_LOG 2>&1
ST=$(grep -o 'At revision\|Updated to revision' $SODEXISSVN_LOG)
if [ -z "$ST" ]; then
    T=$(crontab -l | grep -i "$SCRIPT_NAME" | cut -c -1)
        #Below if condition checks whether cronjob already got commented by openerpsvn funtion. If Not, then comment it.
        if [ "$T" != "#" ]; then
             #Disabled the 5 min cronjob such that for-loop check 5 times = 25 min 
             crontab -l | sed "/^[^#].*$SCRIPT_NAME/s/^/#/" | crontab -
        fi
    for (( c=1; c<=5; c++ ))
    do
         echo $(date) > $SODEXISSVN_LOG
         $SVN update --username $USER --password $PASS --non-interactive --no-auth-cache >> $SODEXISSVN_LOG 2>&1
         ST=$(grep -o 'At revision\|Updated to revision' $SODEXISSVN_LOG)
         if [ -z "$ST" ]; then
               sleep 300
         else
               #Enables the cronjob if variable OT returns non-empty within 5 cycle     
               crontab -l | sed "/^#.*$SCRIPT_NAME/s/^#//" | crontab - 
               break
         fi
    done
fi 
if [ -z "$ST" ]; then   
    echo " " >> $SODEXISSVN_LOG
    echo "Note: Error occured with sodexis repo update. cronjob is stopped. resolve and run the /opt/scripts/$SCRIPT_NAME script manually again by script user." >> $SODEXISSVN_LOG                   
    $MAIL -s "FAILURE - Test server Sciencefirst udpate" -c "$CC1" "$A_EMAIL" < $SODEXISSVN_LOG
fi
}

openerpfn
sodexismodulesfn
sciencefirstfn
sodexisfn

exit 1