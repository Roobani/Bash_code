#!/bin/bash

HOST="demo.sodexis.com"
CONFIGPATH="/etc/odoo-demo.conf"
LOGDIR="/opt/support_files/scripts/logs"
DB=Demo
RDB=/opt/support_files/Demo.dump
LOG=/var/log/odoo-demo/odoo-server.log
PATH=/home/sodexis/virt_env/demo/bin:/bin:/sbin:/usr/bin
VIRTENV=/home/sodexis/virt_env/demo/bin/python
DAEMON=/opt/demo/11.0/odoo-bin
DESC=odoo-demo-11
CHDIR=/opt/demo/11.0/
#Wait time for -u all (in seconds).
UPDATEINSEC="1200"
UPDATE_CONTEXT="Initiating shutdown"
UPDATE_LOG_LEVEL=info
#
MAILADDR="john@sodexis.com"
REPLYTO="john@sodexis.com"
BCC="dailymonitoring@sodexis.com"




#  DONT CHANGE ANYTHING BELOW
#===============================
SCRIPT_NAME=`basename $0`
LOGFILE=$LOGDIR/$SCRIPT_NAME-`date +%N`.log             # Logfile Name
LOGERR=$LOGDIR/$SCRIPT_NAME-ERRORS-`date +%N`.log       # Logfile Name
WARNING=$LOGDIR/$SCRIPT_NAME-WARNING-`date +%N`.log     # Warning log file.

PIDFILE=/var/run/$DESC.pid

DAEMON_START="-c $CONFIGPATH --logfile=${LOG}"
DAEMON_UPDATE="-c $CONFIGPATH --logfile=${LOG} --workers=0 -d $DB -u all --log-level=${UPDATE_LOG_LEVEL} --stop-after-init"

UPDATEINMIN=$(($UPDATEINSEC / 60))
UPDATE_TMP_LOG="/tmp/${DB}-u-all.log"

GREPPROCESS="$(basename $CONFIGPATH | sed 's/./[\0]/')"

DATADIR=`grep 'data_dir' $CONFIGPATH | awk '{print $3}'`/filestore

#DB restore credential
CONNECT_DB_IP=$(grep 'db_host' $CONFIGPATH | awk '{ print $3 }')
CONNECT_DB_PORT=$(grep 'db_port' $CONFIGPATH | awk '{ print $3 }')
CONNECT_DB_NAME=$(grep 'db_template' $CONFIGPATH | awk '{ print $3 }')
CONNECT_DB_USER=$(grep 'db_user' $CONFIGPATH | awk '{ print $3 }')
CONNECT_DB_PASS=$(grep 'db_password' $CONFIGPATH | awk '{ print $3 }')

# Specify the user name
USER=`stat -c '%U' ${DAEMON}`

WORK="$(grep 'workers' $CONFIGPATH)"

# IO redirection for logging.
touch $LOGFILE
exec 6>&1
exec > $LOGFILE
touch $LOGERR
exec 7>&2
exec 2> $LOGERR

email () {
#Clean up IO redirection
exec 1>&6 6>&-      # Restore stdout and close file descriptor #6.
exec 1>&7 7>&-      # Restore stdout and close file descriptor #7.

if [ -s "$LOGERR" -a -s "$LOGFILE" ]; then
    cat "$LOGERR" | mail -s "ERRORS - Database Reset for $HOST" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
    cat "$LOGFILE" | mail -s "SUCCESS - Database Reset for $HOST" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
elif [ -s "$LOGERR" -a ! -s "$LOGFILE" ]; then
    cat "$LOGERR" | mail -s "ERRORS - Database Reset for $HOST" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
else
    cat "$LOGFILE" | mail -s "SUCCESS - Database Reset for $HOST" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
fi

# Clean up Logfile
find "$LOGDIR"/"${SCRIPT_NAME}"-*.log -type f -mtime +3 -exec rm -f {} +
}


ps aux |grep "$GREPPROCESS" >/dev/null
if [ $? -eq 0 ]; then
    start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile ${PIDFILE} --oknodo --exec  ${VIRTENV} ${DAEMON}
    ps aux |grep "$GREPPROCESS" >/dev/null
    if [ $? -eq 0 ]; then
	    for i in $(pgrep -lf "$GREPPROCESS" | awk '{print $1}')
	    do
	        kill -9 $i >/dev/null
	    done
        echo "The $DESC was Forcely killed." >> $LOGERR
        exit 1
    else
        echo "$DESC Stopped successfully."
        echo " "
    fi  
fi


#Session Clear
PGPASSWORD=$CONNECT_DB_PASS psql -h ${CONNECT_DB_IP} -p ${CONNECT_DB_PORT} -d ${CONNECT_DB_NAME} -U ${CONNECT_DB_USER} -w -q -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$DB' AND pid <> pg_backend_pid()"
if [ "$?" -ne "0" ]; then
	echo -e 
	echo -e "Clearning sessions for '${DB}': FAILED" 
	email

	exit 1
fi
sleep 5

#Drop db
PGPASSWORD=$CONNECT_DB_PASS psql -h ${CONNECT_DB_IP} -p ${CONNECT_DB_PORT} -d ${CONNECT_DB_NAME} -U ${CONNECT_DB_USER} -w -q -c "DROP DATABASE \"$DB\""
sleep 5
if [ -z `PGPASSWORD=$CONNECT_DB_PASS psql -h ${CONNECT_DB_IP} -p ${CONNECT_DB_PORT} -d ${CONNECT_DB_NAME} -U ${CONNECT_DB_USER} -w -tAc "SELECT 1 FROM pg_database WHERE datname = '$DB'"` ]; then
	echo -e "Droping the database '${DB}': SUCCESS"
else
	echo -e "Droping the database '${DB}': FAILED"  | mail -s "ERRORS - demo.sodexis.com" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
	exit 1
fi
cd ${DATADIR}/ && cp -Rp $DB ${DB}_bak && rm -rf ${DB}
if [ ! -d "${DATADIR}/${DB}" ]; then
    echo -e "Deleting the filestore for '${DB}': SUCCESS"
else
    echo -e "Deleting the filestore for '${DB}': FAILED" >> $LOGERR
    email
    exit 1
fi

#Restore db
echo -e " "
PGPASSWORD=$CONNECT_DB_PASS psql -h ${CONNECT_DB_IP} -p ${CONNECT_DB_PORT} -d ${CONNECT_DB_NAME} -U ${CONNECT_DB_USER} -w -c "CREATE DATABASE \"$DB\" ENCODING 'unicode' TEMPLATE "${CONNECT_DB_NAME}"" >/dev/null 2>&1
sleep 3
if ! PGPASSWORD=$CONNECT_DB_PASS pg_restore -h ${CONNECT_DB_IP} -p ${CONNECT_DB_PORT} -U ${CONNECT_DB_USER} -e -w -j 4 -O -n public -d "$DB" "$RDB"; then
	echo -e "Restore STATUS for Database '${DB}': FAILED" >> $LOGERR
	psql -d postgres --port=$DB_PORT -c "DROP DATABASE \"$DB\"" >/dev/null 2>&1
	email
	exit 1
else
	echo -e "Restore STATUS for Database '${DB}': SUCCESS"
	echo -e " "
fi
#Restore filestore.
cd ${DATADIR}/ && cp -Rp ${DB}_bak ${DB}
if [ -d "Demo" ]; then
    echo -e "Restoring the Filestore for '${DB}': SUCCESS"
else
    echo -e "Restoring the Filestore for '${DB}': FAILED" >> $LOGERR
    email
    exit 1
fi

echo " "
echo -en "Updating ${DESC} with '${DB}': "
echo -e "UPDATE IN PROGRESS..."
start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
--chuid ${USER} --background --make-pidfile \
--chdir ${CHDIR} --exec ${VIRTENV} ${DAEMON} -- ${DAEMON_UPDATE}
echo -e " "
/usr/bin/timeout $UPDATEINSEC sed "/$UPDATE_CONTEXT/q" > "$UPDATE_TMP_LOG" < <(tail -fn0 "$LOG")
if [ "$?" -eq "124" ]; then
    echo -e "UNKNOWN"
    echo -e " "
    echo -e "Database update taken more than $UPDATEINMIN minutes"
    echo -e "Check the logs"
    sleep 3
    start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile ${PIDFILE} --oknodo --exec  ${VIRTENV} ${DAEMON}
elif grep -oq 'ERROR' $UPDATE_TMP_LOG; then
    echo -e "DONE with Errors"
else
    echo -e "DONE"
    echo -e " "
fi
echo -e " "
sleep 5
printf '%70s\n' | tr ' ' -
start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
--chuid ${USER} --background --make-pidfile \
--chdir ${CHDIR} --exec ${VIRTENV} ${DAEMON} -- ${DAEMON_START}

sleep 5

ps aux |grep "$GREPPROCESS" >/dev/null
if [ $? -eq 0 ]; then
    echo -e "Starting ${DESC}: STARTED with $WORK"
else
    echo -e "Starting ${DESC}: NOT STARTED" >> $LOGERR
fi

email