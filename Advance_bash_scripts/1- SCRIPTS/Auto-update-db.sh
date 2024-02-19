#!/bin/bash

ulimit -n 50000
ulimit -u 50000

HOST="john test"
SCRIPT_NAME=`basename $0`
LOGDIR="/opt/support_files/scripts/logs"
UPDATE_TMP_LOG_DIR=/opt/support_files/scripts/logs

MAILADDR="dailymonitoring@sodexis.com"
ERROR_MAILADDR='skeller@sodexis.com xavier@sodexis.com karthik@sodexis.com ksuganthi@sodexis.com atchuthan@sodexis.com'
REPLYTO="john@sodexis.com"
BCC="john@sodexis.com"
MUTT="$(which mutt)"

# Odoo config path.
CONFIGPATH="/etc/jodee-server-10.conf"

LOG=/var/log/odoo/JOD_10.0/odoo-server.log

PATH=/home/super/virt_env/JOD_10.0/bin:/bin:/sbin:/usr/bin
VIRTENV=/home/super/virt_env/JOD_10.0/bin/python
DAEMON=/opt/odoo/JOD_10.0/10.0/odoo-bin
NAME=jodee-server-10
DESC=jodee-server-10
CHDIR=/opt/odoo/JOD_10.0/10.0/

#Wait time for -u all (in seconds).
UPDATEINSEC="600"
UPDATE_CONTEXT="Computing parent left and right for table ir_ui_menu..."

#Postgresql Access
CONNECT_DB_IP='127.0.0.1'
CONNECT_DB_PORT='5432'
CONNECT_DB_NAME='postgres'
CONNECT_DB_USER='postgres'
CONNECT_DB_PASS='postgres'  


#  DONT CHANGE ANYTHING BELOW
#===============================

# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.2-14) to ensure that this file is present
# and status_of_proc is working.
. /lib/lsb/init-functions

if [ ! -f "${HOME}/.pgpass" ]; then
    echo "${CONNECT_DB_IP}:${CONNECT_DB_PORT}:*:${CONNECT_DB_USER}:${CONNECT_DB_PASS}" > $HOME/.pgpass
    sudo su -c "echo ${CONNECT_DB_IP}:${CONNECT_DB_PORT}:*:${CONNECT_DB_USER}:'${CONNECT_DB_PASS}' > $HOME/.pgpass"
    chmod 0600 $HOME/.pgpass
    sudo su -c "chmod 0600 $HOME/.pgpass"
fi

ODOO_DB_USER="$(grep 'db_user' $CONFIGPATH | awk '{ print $3 }')"

PIDFILE=/var/run/$NAME.pid

#Dont give / at end.
DAEMON_START="-c $CONFIGPATH --logfile=${LOG}"

CONFNAME=$(basename $CONFIGPATH)
GREPPROCESS="$(echo "$CONFNAME" | sed 's/./[\0]/')"

# Specify the user name
USER_CHECK=`echo "$DAEMON" | cut -d/ -f 1-3`
USER=`ls -ld $USER_CHECK | awk '{print $3}'`

WORK="$(grep 'workers' $CONFIGPATH)"

LOGFILE=$LOGDIR/$SCRIPT_NAME-`date +%N`.log             # Logfile Name
LOGERR=$LOGDIR/$SCRIPT_NAME-ERRORS-`date +%N`.log       # Logfile Name
AUTO_UPDATE_STATUS=$LOGDIR/$SCRIPT_NAME-AUTO_UPDATE_STATUS-`date +%N`.log     # Warning log file.

UPDATE_TMP_LOG="$UPDATE_TMP_LOG_DIR/${DB}-u-all.log"
UPDATEINMIN=$(($UPDATEINSEC / 60))

declare -a DBNAME=(`psql -h $CONNECT_DB_IP -p $CONNECT_DB_PORT -d $CONNECT_DB_NAME -U $CONNECT_DB_USER -w --tuples-only -P format=unaligned -c "SELECT datname FROM pg_database JOIN pg_authid ON pg_database.datdba = pg_authid.oid WHERE rolname = '${ODOO_DB_USER}'"`)

# Few checks.
if [ ! -d $(dirname "$(echo "${PATH}" | cut -d: -f1)") ]; then echo; echo "The script could not find PATH:$(echo "${PATH}" | cut -d: -f1)"; echo "Check your virtualenv path and set valid PATH variable in the script"; echo; exit 1; fi
if [ ! -f "${VIRTENV}" ]; then echo; echo "The script could not find VIRTENV path: $(dirname "${VIRTENV}")"; echo "Check your virtualenv path and set valid VIRTENV variable in the script"; echo; exit 1; fi
if [ ! -f "${DAEMON}" ]; then echo; echo "The script could not find DAEMON path: $(dirname "${DAEMON}")"; echo "Check your odoo daemon path and filename exists. Set valid DAEMON variable in the script"; echo; exit 1; fi
if [ ! -d "${CHDIR}" ]; then echo; echo "The script could not find CHDIR path: $(dirname "${DAEMON}")"; echo "Check if your odoo community code directory path and set valid CHDIR variable in the script"; echo; exit 1; fi
if [ ! -f "$(which psql)" ]; then echo; echo " "; echo -e '\e[00;31m'"\033[5m ERRORS \e[00m"; echo -e "The Script Could not find PSQL binaries. See if it is installed."; echo -e "Install using: sudo apt-get install postgresql-client-9.3 "; echo -e "Aborting..""\n"; echo -e "$(yes '-' | head -70 | paste -s -d '' -)"; echo; exit 1; fi
if [ -z "${CONNECT_DB_PORT}" ]; then echo; echo " "; echo -e "Please provide the CONNECT_DB_PORT option in the script"; echo; exit 1; fi
if [ ! -d $(dirname "${LOG}") ]; then echo; echo "The script could not find log directory: $(dirname "${LOG}")"; echo "Check your log directory path and set valid LOG variable in the script"; echo; exit 1; fi
if [ ! -d "${UPDATE_TMP_LOG_DIR}" ]; then echo; echo "The script could not find update log temp directory: "${UPDATE_TMP_LOG_DIR}""; echo "Check your log directory path and set valid UPDATE_TMP_LOG_DIR variable in the script"; echo; exit 1; fi

# IO redirection for logging.
touch $LOGFILE
exec 6>&1
exec > $LOGFILE
touch $LOGERR
exec 7>&2
exec 2> $LOGERR

ps aux |grep "$GREPPROCESS" >/dev/null
if [ $? -eq 0 ]; then
    start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile $PIDFILE --user ${USER}
	RETVAL="$?"
	if [ "$RETVAL" = 2 ]; then
		start-stop-daemon --stop --quiet --oknodo --retry=0/30/KILL/5 --exec $DAEMON --user ${USER}
		if [ "$?" = 2 ]; then
			echo "The $SCRIPT_NAME could not stop the $NAME"
			exit 1
	     fi
	fi	
	# Many daemons don't delete their pidfiles when they exit.
	rm -f $PIDFILE
	sleep 10
fi
for DBI in ${!DBNAME[*]}
do
	DAEMON_UPDATE_ALL="-c $CONFIGPATH --logfile=${LOG} --workers=0 -d ${DBNAME[$DBI]} -u all"
    UPDATE_TMP_LOG="$UPDATE_TMP_LOG_DIR/${DBNAME[$DBI]}-u-all.log"
    start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
	--chuid ${USER} --background --make-pidfile \
	--chdir ${CHDIR} --exec ${VIRTENV} ${DAEMON} -- ${DAEMON_UPDATE_ALL}
	/usr/bin/timeout $UPDATEINSEC sed "/$UPDATE_CONTEXT/q" > "$UPDATE_TMP_LOG" < <(tail -fn0 "$LOG")
	if [ "$?" -eq "124" ]; then
	    echo -e "Updating ${DESC} with '${DBNAME[$DBI]}': UNKNOWN" | tee -a $AUTO_UPDATE_STATUS
	    UNKNOWN_DB_LOG="$UNKNOWN_DB_LOG -a $UPDATE_TMP_LOG"
	    sleep 5
	    start-stop-daemon --stop --quiet --retry=0/30/KILL/5 --pidfile ${PIDFILE} \
	    --oknodo    
	elif grep -oq 'ERROR' $UPDATE_TMP_LOG; then
	    echo -e "Updating ${DESC} with '${DBNAME[$DBI]}': DONE with Errors" | tee -a $AUTO_UPDATE_STATUS
	    ERROR_DB_LOG="$ERROR_DB_LOG -a $UPDATE_TMP_LOG"
	    sleep 5
	    start-stop-daemon --stop --quiet --retry=0/30/KILL/5 --pidfile ${PIDFILE} \
	    --oknodo
	    sleep 10
	else
	    echo -e "Updating ${DESC} with '${DBNAME[$DBI]}': DONE"
	    sleep 5
	    start-stop-daemon --stop --quiet --retry=0/30/KILL/5 --pidfile ${PIDFILE} \
	    --oknodo
	    sleep 10
	fi
	echo -e " "
done
echo -e " "
echo -e "Databases updates completed."
echo -e " "
printf '%80s\n' | tr ' ' -
start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
--chuid ${USER} --background --make-pidfile \
--chdir ${CHDIR} --exec ${VIRTENV} ${DAEMON} -- ${DAEMON_START}

sleep 10

ps aux |grep "$GREPPROCESS" >/dev/null
if [ $? -eq 0 ]; then
    echo -e "Starting ${DESC}: STARTED with $WORK"
    printf '%80s\n' | tr ' ' -
else
    echo -e "Starting ${DESC}: NOT STARTED" >> $LOGERR
    printf '%80s\n' | tr ' ' -
fi

#Clean up IO redirection
exec 1>&6 6>&-      # Restore stdout and close file descriptor #6.
exec 1>&7 7>&-      # Restore stdout and close file descriptor #7.

if [ -s "$LOGERR" -a -s "$LOGFILE" ]; then
    cat "$LOGERR" | mail -s "ERRORS - Database Auto-update for $HOST" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
    cat "$LOGFILE" | mail -s "SUCCESS - Database Auto-update for $HOST" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
elif [ -s "$LOGERR" -a ! -s "$LOGFILE" ]; then
    cat "$LOGERR" | mail -s "ERRORS - Database Auto-update for $HOST" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
else
    cat "$LOGFILE" | mail -s "SUCCESS - Database Auto-update for $HOST" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
fi

if [ -s "$AUTO_UPDATE_STATUS" ]; then
	echo " " >> $AUTO_UPDATE_STATUS
	echo "The ERRORS log file(s) are attached." >> $AUTO_UPDATE_STATUS
	cat "$AUTO_UPDATE_STATUS" | $MUTT $UNKNOWN_DB_LOG $ERROR_DB_LOG -s "UPDATE ERRORS - Database Auto-update for $HOST" -- $MAILADDR $BCC $ERROR_MAILADDR
fi

# Clean up Logfile
find "$LOGDIR"/"${SCRIPT_NAME}"-*.log -type f -mtime +3 -exec rm -f {} +
