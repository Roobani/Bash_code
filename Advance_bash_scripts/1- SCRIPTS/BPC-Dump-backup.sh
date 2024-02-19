#!/bin/bash
#environment
export COMPIERE_HOME="/var/app/compiere/Compiere2"
export JAVA_HOME="/usr/java/latest"
export PATH="$PATH:$COMPIERE_HOME"
export ORACLE_HOME=/var/app/oracle/product/11.2.0/dbhome_1
export PATH="$PATH:$JAVA_HOME/bin:$ORACLE_HOME/bin"
MAIL="$(which mail)"
#name of process
DISPLAY=":1000.0"
NAME=runexport
EMAIL=dailymonitoring@sodexis.com
ALERT_MAIL=john@sodexis.com
ALERT_MAIL1=v.s.elangovan@sodexis.com
BACKUPDIR=/var/app/compiere/Compiere2/data
FTPHOST='backup319.onlinehome-server.com'
FTPUSER='bak4132947'
FTPPASS='k4BAy9G@5'
FTPFOLDER='/BPC-DUMP'
MUTT="$(which mutt)"
LOGFILE=$HOME/scripts/logs/$NAME.log
LOGERR=$HOME/scripts/logs/Error-$NAME.log
UPDATE_TMP_LOG=$HOME/scripts/logs/server.log
EXPDAT_LOG=$COMPIERE_HOME/data/ExpDat.log
BEFORE_COMPIERE_STOP_WAIT=900
WAIT_1MIN=60
WAIT_2MIN=120
touch $UPDATE_TMP_LOG 
>$UPDATE_TMP_LOG
touch $LOGFILE
exec 6>&1           # Link file descriptor #6 with stdout.
                    # Saves stdout.
exec > $LOGFILE     # stdout replaced with file $LOGFILE.
touch $LOGERR
exec 7>&2           # Link file descriptor #7 with stderr.
                    # Saves stderr.
exec 2> $LOGERR     # stderr replaced with file $LOGERR.


jbos_stp () {
pgrep -f jboss &> /dev/null
if [ $? -eq 1 ]; then
    echo
    echo "COMPIERE STOPPED" 
    echo ------------------------------------------
else
    echo "COMPIERE IS STILL RUNNING"
    echo ------------------------------------------
    echo -e "Script executed RUN_Server2Stop.sh but jboss is running.\n\nCOMPIERE IS STILL RUNNING." | mail -s "FAILURE - BPC PRODUCTION Dump Backup" $ALERT_MAIL $ALERT_MAIL1
exit 1
fi
}

jbos_strt () {
pgrep -f jboss &> /dev/null
if [ $? -eq 0 ]; then
    echo
    echo "COMPIERE STARTED" 
    echo ------------------------------------------
else
    echo "COMPIERE IS NOT STARTED !"
    echo ------------------------------------------
    echo -e "Script executed RUN_Server2.sh but jboss is NOT running.\n\nCOMPIERE IS NOT STARTED." | mail -s "FAILURE - BPC PRODUCTION Dump Backup" $ALERT_MAIL $ALERT_MAIL1
exit 1
fi
}

jconso () {
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


echo
# Stop the compiere
cd /var/app/compiere/Compiere2/utils
echo "STARTING DUMP OF BPC PRODUCTION COMPIERE"
echo "=========================================="
echo 
echo "STOPPING Compiere Server..."
echo ------------------------------------------------
echo
sleep $BEFORE_COMPIERE_STOP_WAIT
sh RUN_Server2Stop.sh
sleep $WAIT_2MIN
jbos_stp
sleep $WAIT_1MIN
mv server.log server$(date +%Y-%m-%d_%R)-Dump-Backup.sh.log
echo

if [ $COMPIERE_HOME ]; then
  cd $COMPIERE_HOME/utils
fi
. ./myEnvironment.sh Server
echo    Export Compiere Database - $COMPIERE_HOME \($COMPIERE_DB_NAME\)

#-------------------------------------------
# Modified Script From Oracle/DBExport.sh
echo Saving database $COMPIERE_DB_USER@$COMPIERE_DB_NAME to $COMPIERE_HOME/data/ExpDat.dmp
if [ "$COMPIERE_HOME" = "" -o  "$COMPIERE_DB_NAME" = "" ]
  then
    echo "Please make sure that the environment variables are set correctly:"
    echo "      COMPIERE_HOME   e.g. /Compiere2"
    echo "      COMPIERE_DB_NAME        e.g. compiere.compiere.org"
    exit 1
fi
# Cleanup
sqlplus $COMPIERE_DB_USER/$COMPIERE_DB_PASSWORD@$COMPIERE_DB_NAME @$COMPIERE_HOME/utils/$COMPIERE_DB_PATH/Daily.sql
# Export
#Clean up IO redirection here if not then we have Expdat.log fills over to the $LOGERR
exec 1>&6 6>&-     
exec 1>&7 7>&-
exec >/dev/null 2>&1     
exp $COMPIERE_DB_USER/$COMPIERE_DB_PASSWORD@$COMPIERE_DB_NAME FILE=$COMPIERE_HOME/data/ExpDat.dmp Log=$COMPIERE_HOME/data/ExpDat.log CONSISTENT=Y OWNER=$COMPIERE_DB_USER
exec 6>&1           
exec >> $LOGFILE     
exec 7>&2           
exec 2>> $LOGERR     
echo
cd $COMPIERE_HOME/data
jar cvfM ExpDat.jar ExpDat.dmp ExpDat.log

if [ $COMPIERE_HOME ]; then
  cd $COMPIERE_HOME/utils
fi
echo

echo "Last Few lines from ExpDat.log"
tail -18 $COMPIERE_HOME/data/ExpDat.log
#-------------------------------------------
echo
echo "STARTING Compiere Server..."
echo --------------------------------------------
echo
sleep $WAIT_1MIN
./RUN_Server2.sh > server.log
sed "/Started in/q" > "$UPDATE_TMP_LOG" < <(tail -n 0 -f server.log)
tail -10 server.log
sleep $WAIT_2MIN
jbos_strt
sleep $WAIT_1MIN
jconso
echo 
echo ---------------------------
echo DUMP FILES:-
echo ---------------------------
echo
ls -lah /var/app/compiere/Compiere2/data/ExpDat* | cut -d' ' -f 5-
echo
echo
# Run command when we're done
echo 
echo ------------------------------------------------------
echo -e "DUMP FILES -> FTP (SYNC)"
echo ------------------------------------------------------
echo    
lftp -u $FTPUSER,$FTPPASS $FTPHOST << EOF
mirror --reverse --delete-first -I ExpDat* -X backup/ -X images/ -X import/ -X save/ -v $BACKUPDIR $FTPFOLDER
echo                
cls -lh $FTPFOLDER/ExpDat* | cut -d\' \' -f 20-
quit 0
EOF
echo
echo Backup End `date`
echo ======================================================================
echo
echo Attachments: ExpDat.log, server.log

#Clean up IO redirection
exec 1>&6 6>&-      # Restore stdout and close file descriptor #6.
exec 1>&7 7>&-      # Restore stdout and close file descriptor #7.
#Added by john
TEXT="$(grep "Export terminated successfully with warnings" $EXPDAT_LOG)"
if [ ! -n "$TEXT" -a -s "$LOGERR" ]; then
   cat "$LOGERR" | $MUTT -a $COMPIERE_HOME/data/ExpDat.log -a $UPDATE_TMP_LOG -s "FAILURE - BPC PRODUCTION Dump Backup" $EMAIL
elif [ -n "$TEXT" -a -s "$LOGERR" ]; then
   cat "$LOGERR" | $MUTT -a $COMPIERE_HOME/data/ExpDat.log -a $UPDATE_TMP_LOG -s "ERRORS - BPC PRODUCTION Dump Backup" $EMAIL
else
   cat "$LOGFILE" | $MUTT -a $COMPIERE_HOME/data/ExpDat.log -a $UPDATE_TMP_LOG -s "SUCCESS - BPC PRODUCTION Dump Backup" $EMAIL
fi
exit $?