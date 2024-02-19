#!/bin/bash
SERVER_NAME='Sciencefirst Test'
SCRIPT_NAME=`basename $0`
USER="dev"
PASS="dev_1234"
CRON="$(which crontab)"
SVN="$(which svn)"
MAIL="$(which mailx)"
A_EMAIL=john@sodexis.com
#CC1=skeller@sodexis.com

#Look at the bottom for variables path for repostiory update.


if [ $(id -u) != "1001" ]; then
    echo " "
    echo "This Script must be executed by sodexis user" 1>&2
    exit 1
fi

T1=$(crontab -l | grep -i "$SCRIPT_NAME" | cut -c -1)
#Below if condition checks whether cronjob already got commented by this scipt. This is to enable it, if run manually.
if [ "$T1" == "#" ]; then
    crontab -l | sed "/^#.*$SCRIPT_NAME/s/^#//" | crontab -
    T2=$(crontab -l | grep -i "$SCRIPT_NAME" | cut -c -1)
    if [ "$T2" != "#" ]; then
        date | $MAIL -s "ENABLED - ${SERVER_NAME} svn update" -c "$CC1" "$A_EMAIL"
    fi
fi

svn_update() {
cd $REPO_PATH
echo $(date) > $SVN_LOG
$SVN update --username $USER --password $PASS --non-interactive --no-auth-cache >> $SVN_LOG 2>&1
if grep -oq 'locked' $SVN_LOG; then
    cd $REPO_PATH
    echo $(date) > $SVN_LOG
    $SVN cleanup
    sleep 10
    $SVN update --username $USER --password $PASS --non-interactive --no-auth-cache >> $SVN_LOG 2>&1
    echo " " >> $SVN_LOG
    if grep -oq 'locked' $SVN_LOG; then
        #Disable the crontab if the lock doesn't cleared by some other issue.
        crontab -l | sed "/^[^#].*$SCRIPT_NAME/s/^/#/" | crontab -
        echo " " >> $SVN_LOG
        echo "Note: Working copy ${REPO_NAME} is locked. svn cleanup failed. cronjob is stopped. resolve and run the /opt/support_files/scripts/$SCRIPT_NAME script manually again by script user." >> $SVN_LOG       
        $MAIL -s "FAILURE - ${SERVER_NAME} [${REPO_NAME}] svn update" -c "$CC1" "$A_EMAIL" < $SVN_LOG
        exit 1
    fi
elif grep -oq 'Could not resolve hostname' $SVN_LOG; then
    cd $REPO_PATH
    echo $(date) > $SVN_LOG
    #Disabled the 5 min cronjob such that for-loop check 5 times = 25 min 
    crontab -l | sed "/^[^#].*$SCRIPT_NAME/s/^/#/" | crontab - 
    SEND_EMAIL=true
    for (( c=1; c<=5; c++ ))
    do
        echo $(date) >> $SVN_LOG
        $SVN update --username $USER --password $PASS --non-interactive --no-auth-cache >> $SVN_LOG 2>&1
        OT=$(grep -o 'At revision\|Updated to revision' $SVN_LOG)
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
        echo " " >> $SVN_LOG
        echo "Note: Working copy ${REPO_NAME} could not resolve hostname. cronjob is stopped. resolve and run the /opt/support_files/scripts/$SCRIPT_NAME script manually again by script user." >> $SVN_LOG       
        $MAIL -s "FAILURE - ${SERVER_NAME} [${REPO_NAME}] svn update" -c "$CC1" "$A_EMAIL" < $SVN_LOG
        exit 1
    fi
elif ! grep -oq 'At revision\|Updated to revision' $SVN_LOG; then 
    cd $REPO_PATH
    echo $(date) > $SVN_LOG      
    #Disabled the 5 min cronjob such that for-loop check 5 times = 25 min 
    crontab -l | sed "/^[^#].*$SCRIPT_NAME/s/^/#/" | crontab - 
    SEND_EMAIL=true
    for (( c=1; c<=5; c++ ))
    do
         echo $(date) > $SVN_LOG
         $SVN update --username $USER --password $PASS --non-interactive --no-auth-cache >> $SVN_LOG 2>&1
         OT=$(grep -o 'At revision\|Updated to revision' $SVN_LOG)
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
        echo " " >> $SVN_LOG
        echo "Note: Error occured with ${REPO_NAME} repo update. cronjob is stopped. resolve and run the /opt/support_files/scripts/$SCRIPT_NAME script manually again by script user." >> $SVN_LOG       
        $MAIL -s "FAILURE - ${SERVER_NAME} [${REPO_NAME}] svn update" -c "$CC1" "$A_EMAIL" < $SVN_LOG
        exit 1
    fi
else
    echo " "    
fi
}

#v7.0-SF repository
REPO_NAME=v7.0-SF
REPO_PATH="/opt/openerp-sciencefirst/v7.0/"
SVN_LOG="/opt/support_files/scripts/logs/svn_sf/v7.0_update.log"
svn_update

#sodexismodules-SF repository
REPO_NAME=sodexismodules-SF
REPO_PATH="/opt/openerp-sciencefirst/sodexismodules/"
SVN_LOG="/opt/support_files/scripts/logs/svn_sf/sodexismodules_update.log"
svn_update

#sciencefirst-SF repository
REPO_NAME=sciencefirst-SF
REPO_PATH="/opt/openerp-sciencefirst/sciencefirst/sciencefirst/"
SVN_LOG="/opt/support_files/scripts/logs/svn_sf/sciencefirst_update.log"
svn_update

#sodexis-SF repository
REPO_NAME=sodexis-SF
REPO_PATH="/opt/openerp-sciencefirst/sodexis/sodexis/"
SVN_LOG="/opt/support_files/scripts/logs/svn_sf/sodexis_update.log"
svn_update

#v7.0-CY repository
REPO_NAME=v7.0-CY
REPO_PATH="/opt/openerp-cynmar/v7.0/"
SVN_LOG="/opt/support_files/scripts/logs/svn_cy/v7.0_update.log"
svn_update

#sodexismodules--CY repository
REPO_NAME=sodexismodules-CY
REPO_PATH="/opt/openerp-cynmar/sodexismodules/"
SVN_LOG="/opt/support_files/scripts/logs/svn_cy/sodexismodules_update.log"
svn_update

#sciencefirst--CY repository
REPO_NAME=sciencefirst-CY
REPO_PATH="/opt/openerp-cynmar/sciencefirst/sciencefirst/"
SVN_LOG="/opt/support_files/scripts/logs/svn_cy/sciencefirst_update.log"
svn_update

#sodexis--CY repository
REPO_NAME=sodexis-CY
REPO_PATH="/opt/openerp-cynmar/sodexis/sodexis/"
SVN_LOG="/opt/support_files/scripts/logs/svn_cy/sodexis_update.log"
svn_update