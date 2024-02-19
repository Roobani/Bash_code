#!/bin/bash

# Script to check BPC SVN revision, update local svn and build BPC compiere.
# Written & tested by John (system admin) sodexis.

S_PATH="https://sourceforge.sodexis.com/svn/repos/blueprintsvn/trunk"
L_PATH="/var/app/compiere/blueprint/blueprintsvn/"
ENV_FILE="myDevEnv.sh"
BUILD_LOG="/home/compiere/scripts/logs/build.log"
MAIL_LOG="/home/compiere/scripts/logs/email.log"
MUTT="$(which mutt)"
SVN="$(which svn)"
EMAIL=dailymonitoring@sodexis.com
SVNUSER=admin
SVNPASS=lVI4tTnE

function check_myDevEnv()
{
cd $L_PATH/utils_dev
        if [ ! -f $ENV_FILE ]; then
                cp myDevEnvTemplate.sh myDevEnv.sh
                sed -i -e 's_"export COMPIERE_ROOT=/compiere"_"export COMPIERE_ROOT=/var/app/compiere/blueprint"_g' myDevEnv.sh
                sed -i -e 's_"export COMPIERE_INSTALL=/compiere/install"_"export COMPIERE_INSTALL=/var/app/compiere/blueprint/install"_g' myDevEnv.sh
        fi
}

function run_build()
{
cd $L_PATH/utils_dev
sh RUN_build.sh >> $BUILD_LOG
t1=$(grep -i -e 'complete:' $BUILD_LOG)
        if [ "$t1" == "complete:" ]; then
                echo "Date: $(date)" >$MAIL_LOG
                chmod 770 $MAIL_LOG
                echo "Hostname: $(hostname)" >>$MAIL_LOG
                echo " " >>$MAIL_LOG
                echo "Server Repo Path: $S_PATH" >>$MAIL_LOG
                echo "Server revision: $server_revision" >>$MAIL_LOG
                echo " " >>$MAIL_LOG
                echo "Local Repo Path: $L_PATH" >>$MAIL_LOG
                echo "Local Revision: $local_revision" >>$MAIL_LOG
                echo " " >>$MAIL_LOG
                tail -10 $BUILD_LOG >>$MAIL_LOG
                cat $MAIL_LOG | $MUTT -a $BUILD_LOG -s "SUCCESS - BPC Compiere Build" $EMAIL
                sleep 5
        else
                echo -e "\033[1mLog $BUILD_LOG attached.\033[0m" >$TEMP_LOG
                cat $MAIL_LOG | $MUTT -a $BUILD_LOG -s "FAILURE - BPC Compiere Build" $EMAIL
                exit 1
        fi
}

server_revision="$(svn info --username "$SVNUSER" --password "$SVNPASS" --non-interactive --no-auth-cache https://sourceforge.sodexis.com/svn/repos/blueprintsvn/trunk | grep "^Revision:" | cut -c 11-)"

# Check if server_revision is an integer, if gives some wired error, go to else part and email the error.
#if expr $server_revision + 1 &> /dev/null ; then
if [ -n "$server_revision" ]; then

local_revision="$(svn info --username "$SVNUSER" --password "$SVNPASS" --non-interactive --no-auth-cache /var/app/compiere/blueprint/blueprintsvn/ | grep "^Revision:" | cut -c 11-)"
        if [ "$server_revision" -ne "$local_revision" ]; then
                echo "-----BPC SVN Update and Compiere BUILD-----" >$BUILD_LOG
                chmod 770 $BUILD_LOG
                echo " " >>$BUILD_LOG
                echo "Server Revision: $server_revision" >>$BUILD_LOG
                echo "Local Revision: $local_revision" >>$BUILD_LOG
                echo " " >>$BUILD_LOG
                cd $L_PATH
                $SVN update --username "$SVNUSER" --password "$SVNPASS" --non-interactive --no-auth-cache >> $BUILD_LOG 2>&1
                check_myDevEnv
                run_build
        fi
else
        echo "ERROR:" >$MAIL_LOG
        chmod 770 $MAIL_LOG
        echo " " >>$MAIL_LOG
        $SVN info --username "$SVNUSER" --password "$SVNPASS" --non-interactive --no-auth-cache https://sourceforge.sodexis.com/svn/repos/blueprintsvn/trunk >> $MAIL_LOG 2>&1
        echo " " >>$MAIL_LOG
        echo " " >>$MAIL_LOG
        echo "RESOLUTION:" >>$MAIL_LOG
        echo " " >>$MAIL_LOG
        echo "This error occur, maily due to if SVN server centificate is missing from local server," >>$MAIL_LOG
        echo "or SVN server certificate is changed. Hence, From 'bluerpint' user run the command 'svn info'" >>$MAIL_LOG
        echo "being in the directory of blueprintsvn. It will ask to accept certificate permanently. press [p]." >>$MAIL_LOG
        echo "Login with svn credential username and password. svn info shows revision. exit out." >>$MAIL_LOG
        mail -s "FAILURE - BPC Compiere Build" $EMAIL < $MAIL_LOG
fi
exit 1