#!/bin/bash

# AUTHOR:                       John Britto
# PROFESSION:                   System Administrator
# COPYRIGHTS:                   Sodexis Inc.

. /lib/lsb/init-functions
SETTINGS="$(dirname $(readlink -f $0))"/settings

if [ ! -f "$SETTINGS" ]; then echo "The script could not find source settings file."; exit 1; fi
source "$SETTINGS"

#Checks root permission
if [ $(id -u) != "0" ]; then
        echo " "
        echo -e '\e[00;31m'"\033[5m ERRORS \e[00m"
        echo -e "The current user id:$(id -u) is not member of sudo group"
        echo -e "You must run this script as 'sudo' group user (OR) root user" >&2
        echo -e "No changes made to odoo-server.""\n"
        echo -e "Aborting..""\n"
        echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
        exit 1
fi

# Few checks.
if [ ! -d "${VIRTENV_PATH}" ]; then echo; echo "The script could not find virtual env path: $(dirname "${VIRTENV}")"; echo "Check your virtual env path and set valid VIRTENV_PATH variable in the settings file"; echo; exit 1; fi
if [ ! -f "${DAEMON}" ]; then echo; echo "The script could not find DAEMON path: $(dirname "${DAEMON}")"; echo "Check your odoo daemon path and filename exists. Set valid DAEMON variable in the settings file"; echo; exit 1; fi
if [ ! -f "$(which psql)" ]; then echo; echo " "; echo -e '\e[00;31m'"\033[5m ERRORS \e[00m"; echo -e "The Script Could not find PSQL binaries. See if it is installed."; echo -e "Install using: sudo apt-get install postgresql-client-<postgresql-verison> "; echo -e "Aborting..""\n"; echo -e "$(yes '-' | head -70 | paste -s -d '' -)"; echo; exit 1; fi
if [ ! -d $(dirname "${LOG}") ]; then echo; echo "The script could not find log directory: $(dirname "${LOG}")"; echo "Check your log directory path and set valid LOG variable in the settings file"; echo; exit 1; fi

# Kernel resources.
ulimit -n ${OPEN_FILE_DESCRIPTORS}  # The maximum number of processes available to a single user [Used by wkhtmltopdf to process build report]
ulimit -u ${NUM_OF_PROCESSES}  # The maximum number of open file descriptors [required while printing >1024 Sales orders]

# Database Dump / Restore specific
DB=$2
RDB=$3

PATH="${VIRTENV_PATH}"/bin:/bin:/sbin:/usr/bin
VIRTENV="${VIRTENV_PATH}"/bin/python
CHDIR="$(dirname "${DAEMON}")"/

#Table to exclude during dump.
EXCLUDE_TABLE_DATA="--exclude-table-data=ir_attachment --exclude-table-data=message_attachment_rel --exclude-table-data=mail_compose_message_ir_attachments_rel --exclude-table-data=email_template_attachment_rel"

#Very important. for start-stop-daemon to start/stop odoo-server.
PIDFILE=/var/run/$NAME.pid

# Log Level
LOG_LEVEL="info debug_rpc warn test critical debug_sql error debug debug_rpc_answer notset"
CASE=$1
CHECK_LOG_LEVEL=$2
ERRORS=$3

GREPPROCESS="$(basename $CONFIGPATH | sed 's/./[\0]/')"
COUNTPROCESS=`ps aux |grep "$GREPPROCESS"| wc -l`

#To check if odoo is already run by eclipse
ECLIGREP="$(echo "org.python.pydev" | sed 's/./[\0]/')"
ECLICOUNT=`ps aux |grep "$ECLIGREP"| wc -l`

WORK="$(grep 'workers' $CONFIGPATH)"

#options that are passed to the Daemon.
DAEMON_START="-c $CONFIGPATH --logfile=${LOG}"
DAEMON_DUMPSTART="-c $CONFIGPATH --logfile=${LOG} --workers=0"
DAEMON_UPDATE="-c $CONFIGPATH --logfile=${LOG} --workers=0 -d $DB -u all --log-level=${UPDATE_LOG_LEVEL}"
UPDATEINMIN=$(($UPDATEINSEC / 60))

#Used for cleaning the filestore while dropping db.
DATADIR=`grep 'data_dir' $CONFIGPATH | awk '{print $3}'`/filestore

#DB credential
CONNECT_DB_IP=$(grep 'db_host' $CONFIGPATH | awk '{ print $3 }')
CONNECT_DB_PORT=$(grep 'db_port' $CONFIGPATH | awk '{ print $3 }')
CONNECT_DB_NAME=$(grep 'db_template' $CONFIGPATH | awk '{ print $3 }')
CONNECT_DB_USER=$(grep 'db_user' $CONFIGPATH | awk '{ print $3 }')
CONNECT_DB_PASS=$(grep 'db_password' $CONFIGPATH | awk '{ print $3 }')

# Specify the user name
USER=`stat -c '%U' ${DAEMON}`

#=======================================================================================================================================
DBNAME=(`PGPASSWORD=$CONNECT_DB_PASS psql -h $CONNECT_DB_IP -p $CONNECT_DB_PORT -d $CONNECT_DB_NAME -U $CONNECT_DB_USER -w --tuples-only -P format=unaligned -c "select datname from pg_database where datdba=(select usesysid from pg_user where usename = '${CONNECT_DB_USER}')"`);

_session_clear() {
    if [ ! -z $OP ]; then
        DB=${DBNAME[$OP]}
        LINEBF=$((${#DBNAME[@]} + 10))
        echo -en "\e[r\e[$(($LINEBF))H"
        echo -e "Checking connections for database '${DB}':\e[00;32m \033[5m OK \e[00m"
        echo -e " "
    else
        echo -e "\e[00;32m \033[5m OK \e[00m"
        echo -e " "
    fi
    echo -e "The Running Connections are:"
    echo -e " "
    PGPASSWORD=$CONNECT_DB_PASS psql -h ${CONNECT_DB_IP} -p ${CONNECT_DB_PORT} -d ${CONNECT_DB_NAME} -U ${CONNECT_DB_USER} -w -c "SELECT datid,datname,pid,usename,state FROM pg_stat_activity WHERE pg_stat_activity.datname = '$DB'"
    read -p "Do you need to force kill the connections [y/n]?" char
    echo -e " "
    case "$char" in
        y|Y )
        PGPASSWORD=$CONNECT_DB_PASS psql -h ${CONNECT_DB_IP} -p ${CONNECT_DB_PORT} -d ${CONNECT_DB_NAME} -U ${CONNECT_DB_USER} -w -q -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$DB' AND pid <> pg_backend_pid()"
        if [ "$?" -eq "0" ]; then
            echo -e "Terminating connections for '${DB}':\e[00;32m \033[5m KILLED \e[00m"
        else
            echo -e "Terminating connections for '${DB}':\e[00;31m \033[5m FAILED \e[00m"
        fi
        ;;
        n|N )
        echo -e '\e[00;32m'"\033[5m CANCELLED \e[00m"
        ;;
        * ) echo "Invalid Input, press y/n"
        ;;
    esac
}

_drop_db() {
    if [ ! -z $OP ]; then
        DB=${DBNAME[$OP]}
        LINEBF=$((${#DBNAME[@]} + 10))
        echo -en "\e[r\e[$(($LINEBF))H"
        echo -e "Checking database '${DB}' to drop:\e[00;32m \033[5m OK \e[00m"
        echo -e " "
    else
        echo -e "\e[00;32m \033[5m OK \e[00m"
        echo -e " "
    fi
    PGPASSWORD=$CONNECT_DB_PASS psql -h ${CONNECT_DB_IP} -p ${CONNECT_DB_PORT} -d ${CONNECT_DB_NAME} -U ${CONNECT_DB_USER} -w -q -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$DB' AND pid <> pg_backend_pid()"
    if [ "$?" -eq "0" ]; then
        echo -e "Terminating connections for '${DB}':\e[00;32m \033[5m SUCCESS \e[00m"
    else
        echo -e "Terminating connections for '${DB}':\e[00;31m \033[5m FAILED \e[00m"
    fi
    echo -e " "
    echo -n "Dropping the database '${DB}':"
    PGPASSWORD=$CONNECT_DB_PASS psql -h ${CONNECT_DB_IP} -p ${CONNECT_DB_PORT} -d ${CONNECT_DB_NAME} -U ${CONNECT_DB_USER} -w -q -c "DROP DATABASE \"$DB\""
    sleep 5
    if [ -z `PGPASSWORD=$CONNECT_DB_PASS psql -h ${CONNECT_DB_IP} -p ${CONNECT_DB_PORT} -d ${CONNECT_DB_NAME} -U ${CONNECT_DB_USER} -w -tAc "SELECT 1 FROM pg_database WHERE datname = '$DB'"` ] && [ "$DB" != "all" ]; then
        echo -e '\e[00;32m'"\033[5m SUCCESS \e[00m"
    else
        echo -e '\e[00;31m' "\033[5m FAILED \e[00m"
    fi
    echo -e " "
    echo -n "Deleting the filestore for '${DB}':"
    cd ${DATADIR}/ && rm -rf ${DB}
    if [ ! -d "${DATADIR}/${DB}" ]; then
        echo -e '\e[00;32m'"\033[5m SUCCESS \e[00m"
    else
        echo -e '\e[00;31m' "\033[5m FAILED \e[00m"
    fi
}

_rename_db() {
    echo -e "The Database ${DB} will be renamed to ${RDB} :"
    echo -e " "
    read -p "Do you confirm [y/n]?" char
    echo -e " "
    case "$char" in
        y|Y )
        PGPASSWORD=$CONNECT_DB_PASS psql -h ${CONNECT_DB_IP} -p ${CONNECT_DB_PORT} -d ${CONNECT_DB_NAME} -U ${CONNECT_DB_USER} -w -q -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$DB' AND pid <> pg_backend_pid()" >/dev/null 2>&1
        sleep 5
        PGPASSWORD=$CONNECT_DB_PASS psql -h ${CONNECT_DB_IP} -p ${CONNECT_DB_PORT} -d ${CONNECT_DB_NAME} -U ${CONNECT_DB_USER} -w -q -c "ALTER DATABASE '$DB' RENAME TO '$RDB'";
        break
        ;;
        n|N )
        echo -e '\e[00;32m'"\033[5m CANCELLED \e[00m"
        break
        ;;
        * ) echo "Invalid Input, press y/n"
        break
        ;;
    esac

}

_check_pid() {
    sleep 5
    # Necessary to add the variable inside daemon to catch the correct value.
    PIDFILE=/var/run/$NAME.pid
    pid=`cat $PIDFILE`
    if [ ! -f $PIDFILE -o ! -d /proc/$pid ]; then
        echo -e '\e[00;31m' "\033[5m ERRORS \e[00m"
        echo -e " "
        echo -e "Running $PIDFILE could not found."
        if ps aux |grep "$GREPPROCESS" >/dev/null; then
            echo -e " "
            echo -e "This Script found NON daemon running Instance:-"
            printf '%70s\n' | tr ' ' -
            echo -e "$(pgrep -lf "$GREPPROCESS")"
            echo -e "\n"
            echo -e "To KILL, use cmd:"
            printf '%70s\n' | tr ' ' -
            for i in $(pgrep -lf "$GREPPROCESS" | awk '{print $1}')
            do
                echo -e "kill -9 $i"
            done
        fi
        echo -e " "
        echo -e "Try Starting the ${NAME} again.."
        echo -e " "
        echo -e "No changes made to ${NAME}.""\n"
        echo -e "Aborting.."
        printf '%70s\n' | tr ' ' -
        echo -e "\n"
        exit 1
    fi
}

_check_db() {
    if [ -z `PGPASSWORD=$CONNECT_DB_PASS psql -h ${CONNECT_DB_IP} -p ${CONNECT_DB_PORT} -d ${CONNECT_DB_NAME} -U ${CONNECT_DB_USER} -w -tAc "SELECT 1 FROM pg_database WHERE datname = '$DB'"` ] && [ "$DB" != "all" ]; then
        echo -e '\e[00;31m'"\033[5m DATABASE NOT EXIST \e[0m"
        echo -e " "
        echo -e "The Available Databases are:-"
        printf '%70s\n' | tr ' ' -
        for ((i = 0; i < ${#DBNAME[@]}; ++i)); do
          position=$(( $i + 1 ))
          echo "$position. ${DBNAME[$i]}" | sed "s/^/   /"
        done
        echo -e " "
        read -p ':: Please enter the option to proceed: ' OP
        if [ $OP -le 0 -o $OP -gt ${#DBNAME[@]} ]; then
          echo -e "Wrong options given."
          echo -e "No changes made to ${NAME}."
          printf '%70s\n' | tr ' ' -
          echo -e "\n"
          exit 1
        fi
        OP=$((OP - 1))
        echo -e " "
    fi
}

_start_loglevel() {
    if [ "$CASE" == "start" ]; then
        START="Starting"
    else
        START="Restarting"
    fi
    if [ ! -z "$CHECK_LOG_LEVEL" -a ! -z "$ERRORS" ]; then
        echo -e '\e[00;31m' "\033[5m ERRORS \e[00m"
        echo -e " "
        echo -e "Error: Log-Level given \e[4m$CHECK_LOG_LEVEL $ERRORS\e[0m does Not Match with any of ${NAME} Log-Level!"
        echo -e " "
        echo -e "The Accepted log-levels are: info, debug_rpc, warn, test, critical, debug_sql, error, debug, debug_rpc_answer, notset"
        echo -e " "
        echo -e "No changes made to ${NAME}.""\n"
        echo -e "Aborting.."
        printf '%70s\n' | tr ' ' -
        echo -e "\n"
        exit 1
    elif [ ! -z "$CHECK_LOG_LEVEL" -a -z "$ERRORS" ]; then
        if grep -qw "$CHECK_LOG_LEVEL" <<< "$LOG_LEVEL"; then
            DAEMON_START="-c $CONFIGPATH --logfile=${LOG} --log-level=$CHECK_LOG_LEVEL"
        else
            echo -e '\e[00;31m' "\033[5m ERRORS \e[00m"
            echo -e " "
            echo -e "Error: Log-Level given \e[4m$CHECK_LOG_LEVEL $ERRORS\e[0m does Not Match with any of ${NAME} Log-Level!"
            echo -e " "
            echo -e "The Accepted log-levels are: info, debug_rpc, warn, test, critical, debug_sql, error, debug, debug_rpc_answer, notset"
            echo -e " "
            echo -e "No changes made to ${NAME}.""\n"
            echo -e "Aborting.."
            printf '%70s\n' | tr ' ' -
            echo -e "\n"
            exit 1
        fi
    else
        DAEMON_START="-c $CONFIGPATH --logfile=${LOG}"
    fi
}

_restart() {
    ps aux |grep "$GREPPROCESS" >/dev/null
    if [ $? -eq 0 ]; then
        start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile ${PIDFILE} --oknodo --exec ${VIRTENV} ${DAEMON}

        sleep 10

        start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
        --chuid ${USER} --background --make-pidfile \
        --chdir ${CHDIR} --exec ${VIRTENV} ${DAEMON} -- ${DAEMON_START}
    else
        sleep 10

        start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
        --chuid ${USER} --background --make-pidfile \
        --chdir ${CHDIR} --exec ${VIRTENV} ${DAEMON} -- ${DAEMON_START}
    fi
}


_update() {
    ps aux |grep "$GREPPROCESS" >/dev/null
    if [ $? -eq 0 ]; then
        start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile ${PIDFILE} --oknodo --exec  ${VIRTENV} ${DAEMON}
        ps aux |grep "$GREPPROCESS" >/dev/null
        if [ $? -eq 0 ]; then
            echo -e '\e[r\e[3H'
            echo -e "Updating ${NAME} with '${DB}': "'\e[00;31m'"\033[5m ERRORS \e[00m"
            echo -e " "
            echo -e "Stopping of ${NAME} failed.."
            echo -e " "
            echo -e "The Running Instance are:-"
            printf '%70s\n' | tr ' ' -
            echo -e "$(pgrep -lf "$GREPPROCESS")"
            echo -e "\n"
            echo -n "Attempting to KILL running PID: "
            for i in $(pgrep -lf "$GREPPROCESS" | awk '{print $1}')
            do
                kill -9 $i >/dev/null
            done
            PD1=$(pgrep -lf "$GREPPROCESS" | awk '{print $1}')
            if [ ! -z "$PD1" ]; then
                echo -e '\e[00;31m'"\033[5m FAILED \e[00m"
                echo -e "No changes made to ${NAME}.""\n"
                echo -e "Aborting.."
                printf '%70s\n' | tr ' ' -
                echo -e "\n"
                exit 1
            else
                echo -e '\e[00;32m'"\033[5m SUCCESS \e[00m"
            fi
        fi
    fi
    if [ "$DB" == "all" ]; then
        echo -en '\e[r\e[3H'
        for DBI in ${!DBNAME[*]}
        do
            DAEMON_UPDATE_ALL="-c $CONFIGPATH --logfile=${LOG} --workers=0 -d ${DBNAME[$DBI]} -u all --log-level=${UPDATE_LOG_LEVEL}"
            UPDATE_TMP_LOG="/tmp/${DBNAME[$DBI]}-u-all.log"
            echo -e "Updating ${NAME} with '${DBNAME[$DBI]}': "'\e[00;32m'"\033[5m UPDATE IN PROGRESS \e[00m"
            echo -e " "
            start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
            --chuid ${USER} --background --make-pidfile \
            --chdir ${CHDIR} --exec ${VIRTENV} ${DAEMON} -- ${DAEMON_UPDATE_ALL}
            echo -e " "
            echo -n "Waiting for Database Update status: "
            /usr/bin/timeout $UPDATEINSEC sed "/$UPDATE_CONTEXT/q" > "$UPDATE_TMP_LOG" < <(tail -fn0 "$LOG")
            if [ "$?" -eq "124" ]; then
                echo -e '\e[00;31m'"\033[5m UNKNOWN \e[00m"
                echo -e " "
                echo -e "It seems Database update is hanged. This script waited $UPDATEINMIN minutes and could not find \e[4m ${NAME} is running/ waiting for connection \e[00m written state from the logs."
                sleep 3
                start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile ${PIDFILE} --oknodo --exec  ${VIRTENV} ${DAEMON}
            elif grep -oq 'ERROR' $UPDATE_TMP_LOG; then
                echo -e '\e[00;33m'"\033[5m DONE with Errors \e[00m"
                sleep 3
                start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile ${PIDFILE} --oknodo --exec ${VIRTENV} ${DAEMON}
            else
                echo -e '\e[00;32m'"\033[5m DONE \e[00m"
                sleep 3
                start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile ${PIDFILE} --oknodo --exec ${VIRTENV} ${DAEMON}
            fi
        done
        echo -e " "
        echo -e "Updating ${NAME} with ALL Available Databases Completed."
        echo -e " "
        printf '%70s\n' | tr ' ' -
        echo -n "Starting ${NAME}: "
        start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
        --chuid ${USER} --background --make-pidfile \
        --chdir ${CHDIR} --exec ${VIRTENV} ${DAEMON} -- ${DAEMON_START}
    else
        if [ ! -z $OP ]; then
            DB=${DBNAME[$OP]}
            echo -en "Updating ${NAME} with database '${DB}': "
        fi
        UPDATE_TMP_LOG="/tmp/${DB}-u-all.log"
        DAEMON_UPDATE="-c $CONFIGPATH --logfile=${LOG} --workers=0 -d $DB -u all --log-level=${UPDATE_LOG_LEVEL}"
        echo -e '\e[00;32m'"\033[5m UPDATE IN PROGRESS \e[00m"
        start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
        --chuid ${USER} --background --make-pidfile \
        --chdir ${CHDIR} --exec ${VIRTENV} ${DAEMON} -- ${DAEMON_UPDATE}
        echo -e " "
        echo -e "Check the logs..."
        echo -e " "
        echo -n "Waiting for Database Update status: "
        /usr/bin/timeout $UPDATEINSEC sed "/$UPDATE_CONTEXT/q" > "$UPDATE_TMP_LOG" < <(tail -fn0 "$LOG")
        if [ "$?" -eq "124" ]; then
            echo -e '\e[00;31m'"\033[5m UNKNOWN \e[00m"
            echo -e " "
            echo -e "The Database update taking more than $UPDATEINMIN minutes."
            echo -e "Check the log to see if the update is still ON."
            echo -e " "
            echo -e "NOTE: ${NAME} is running with single process mode. Stop and start the script."
            echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
            echo -e "\n"
            exit 1
        elif grep -oq 'ERROR' $UPDATE_TMP_LOG; then
            echo -e '\e[00;33m'"\033[5m DONE with Errors \e[00m"
            sleep 5
            start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile ${PIDFILE} --oknodo --exec ${VIRTENV} ${DAEMON}
        else
            echo -e '\e[00;32m'"\033[5m DONE \e[00m"
            echo -e " "
            sleep 5
            start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile ${PIDFILE} --oknodo --exec ${VIRTENV} ${DAEMON}
        fi
        echo -e " "
        printf '%70s\n' | tr ' ' -
        echo -n "Starting ${NAME}: "
        start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
        --chuid ${USER} --background --make-pidfile \
        --chdir ${CHDIR} --exec ${VIRTENV} ${DAEMON} -- ${DAEMON_START}
    fi
}

_postcheck() {
    if [ "$CASE" == "start" ]; then
        ps aux |grep "$GREPPROCESS" >/dev/null
        if [ $? -eq 0 ]; then
            if [ -z "$CHECK_LOG_LEVEL" ]; then
                echo -e '\e[00;32m'"\033[5m STARTED \e[00m with $WORK"
            else
                echo -e '\e[00;32m'"\033[5m STARTED wth Log-level = $CHECK_LOG_LEVEL \e[00m"
            fi
        else
            echo -e '\e[00;31m' "\033[5m NOT $ST \e[00m"
        fi
    elif [ "$CASE" == "restart" ]; then
        ps aux |grep "$GREPPROCESS" >/dev/null
        if [ $? -eq 0 ]; then
               if [ -z "$CHECK_LOG_LEVEL" ]; then
                         echo -e '\e[00;32m'"\033[5m RESTARTED \e[00m with $WORK"
                   else
                 echo -e '\e[00;32m'"\033[5m RESTARTED wth Log-level = $CHECK_LOG_LEVEL \e[00m"
                   fi
        else
            echo -e '\e[00;31m' "\033[5m NOT $ST \e[00m"
        fi
    elif [[ "$CASE" == "update" ]] || [[ "$CASE" == "startdump" ]]; then
        ps aux |grep "$GREPPROCESS" >/dev/null
        if [ $? -eq 0 ]; then
            if [ "$CASE" == "startdump" ]; then
                echo -e '\e[00;32m'"\033[5m STARTED with worker=0 \e[00m"
            else
                echo -e '\e[00;32m'"\033[5m STARTED \e[00m"
            fi
        else
            echo -e '\e[00;31m' "\033[5m NOT STARTED \e[00m"
        fi
    elif [ "$CASE" == "stop" ]; then
        ps aux |grep "$GREPPROCESS" >/dev/null
        if [ $? -eq 0 ]; then
            echo -e '\e[00;31m' "\033[5m NOT STOPPED \e[00m"
            echo " "
            T1=$(ps aux |grep "$GREPPROCESS")
            echo -e "Running $COUNTPROCESS instances are as follow:-"
            echo " "
            echo "$T1"
        else
            echo -e '\e[00;32m'"\033[5m STOPPED \e[00m"
        fi
    else
        echo " "
    fi
}

_dump_db() {
    if [ ! -z $OP ]; then
       DB=${DBNAME[$OP]}
       LINEBF=$((${#DBNAME[@]} + 21))
       #Total no. of output lines to show during pgdump
       LINEAF=$(($LINEBF + 11))
       echo -en "Preparing database '${DB}' for dump: "
    fi
    if [ ! -d $(dirname $RDB) ]; then
        echo -e '\e[00;31m' "\033[5m ERROR \e[00m"; echo " "; echo -e "The dump output directory $(dirname $RDB), does not exists."; echo " "; printf '%70s\n' | tr ' ' -; echo -e "\n"
        exit 1
    elif [ -f "$RDB" ]; then
        echo -e '\e[00;31m' "\033[5m ERROR \e[00m"; echo " "; echo -e "The Dump output file name in Path: $RDB is already exists."\n"Please give any other Dump output file name."; echo " "; printf '%70s\n' | tr ' ' -; echo -e "\n"
        exit 1
    else
        echo -e '\e[00;32m'"\033[5m OK \e[00m"
        echo " "
    fi
    PS3=$'\n:: Please enter your choice: '
    options=("Dump (Including Filestore)" "Dump (Excluding Filestore)" "Dump (Excluding Filestore & Reference tables)" "Quit")
    select opt in "${options[@]}"
    do
        case $opt in
            "Dump (Including Filestore)")
                echo " "
                DS="Dump STATUS for Database '${DB}' Including Filestore:"
                EXCLUDE_TABLE_DATA=""
                TAR=1
                echo -en "$DS"
                break
                ;;
            "Dump (Excluding Filestore)")
                echo " "
                DS="Dump STATUS for Database '${DB}' Excluding Filestore:"
                EXCLUDE_TABLE_DATA=""
                echo -en "$DS"
                break
                ;;
            "Dump (Excluding Filestore & Reference tables)")
                echo " "
                DS="Dump STATUS for Database '${DB}' Excluding Filestore & Reference tables:"
                echo -en "$DS"
                break
                ;;
            "Quit")
                echo " "
                break
                ;;
            *) echo invalid option
            exit 1
            ;;
        esac
    done
    if [ ! -z $OP ]; then
        echo -en "\e[${LINEBF};${LINEAF}r\e[${LINEBF}H"
        STATUS_MSG_PRINT="\e[r\e[$(($LINEBF - 2))H"
        SIZE_MSG_PRINT="\e[r\e[$(($LINEAF + 2))H"
    else
        echo -en '\e[12;21r\e[12H'
        STATUS_MSG_PRINT='\e[r\e[10H'
        SIZE_MSG_PRINT='\e[r\e[22H'
    fi

    if ! PGPASSWORD=$CONNECT_DB_PASS pg_dump -U ${CONNECT_DB_USER} -h ${CONNECT_DB_IP} -p ${CONNECT_DB_PORT} -w -Fc -v -O -x ${EXCLUDE_TABLE_DATA} "$DB" > "$RDB"; then
        echo -e "pg_dump: Error"
        echo -en '\e[r\e[10H'
        echo -e "${DS}"'\e[00;31m' "\033[5m FAILED \e[00m"
        echo -en '\e[r\e[22H'
        printf '%70s\n' | tr ' ' -
        echo -e "\n"
        exit 1
    fi
    echo -e "pg_dump: Done"
    if [ ! -z "$TAR" ]; then tar -czf "$(dirname $RDB)"/"$(basename "$RDB" | cut -d'.' -f1)".tar.gz -C ${DATADIR} ${DB} -C $(dirname $RDB) $(basename $RDB); rm -f ${RDB}; fi
    echo -en $STATUS_MSG_PRINT
    echo -e "${DS}"'\e[00;32m'"\033[5m SUCCESS \e[00m"
    echo -en $SIZE_MSG_PRINT
    echo -e " "
    check=`du -hs "$(dirname $RDB)"/"$(basename "$RDB" | cut -d'.' -f1)"*`
    echo "Dump Size: $(echo $check | awk '{ print $1 }')"
    echo "Dump Location: $(echo $check | awk '{ print $2 }')"
    echo -e " "
}

_restore_db() {
    if [[ ! -z `PGPASSWORD=$CONNECT_DB_PASS psql -h ${CONNECT_DB_IP} -p ${CONNECT_DB_PORT} -d ${CONNECT_DB_NAME} -U ${CONNECT_DB_USER} -w -tAc "SELECT 1 FROM pg_database WHERE datname = '$DB'"` ]]; then
        echo -e '\e[00;31m' "\033[5m ERROR \e[00m"; echo " "; echo -e "The Database name already Exists."; echo " "; printf '%70s\n' | tr ' ' -; echo -e "\n"
        exit 1
    elif [ ! -f "$RDB" ]; then
        echo -e '\e[00;31m' "\033[5m ERROR \e[00m"; echo " "; echo -e "$RDB Does Not Exists. Check the path and permission."; echo " "; printf '%70s\n' | tr ' ' -; echo -e "\n"
        exit 1
    elif [ "$(basename "$RDB" | cut -d'.' -f2)" == "tar" ]; then
        TR="/tmp/restore/"
        if [ ! -d "$TR" ]; then mkdir $TR; fi
        if tar -xzf "$RDB" -C "$TR"; then
            cd $TR && FS=`ls -d */ | cut -f1 -d'/'` && RDB=`ls -pa | grep -v /`
            echo -e '\e[00;32m'"\033[5m OK \e[00m"
            echo -e "\n"
        else
            echo -e '\e[00;31m' "\033[5m ERROR \e[00m"; echo " "; echo -e "Error while extracting the $RDB"; echo " "; printf '%70s\n' | tr ' ' -; echo -e "\n"
            exit 1
        fi
    else
        echo -e '\e[00;32m'"\033[5m OK \e[00m"
        echo -e "\n"
    fi

    echo -en "Restore STATUS for Database '${DB}': "
    date1=$(date +"%s")
      PGPASSWORD=$CONNECT_DB_PASS psql -h ${CONNECT_DB_IP} -p ${CONNECT_DB_PORT} -d ${CONNECT_DB_NAME} -U ${CONNECT_DB_USER} -w -c "CREATE DATABASE \"$DB\" ENCODING 'unicode' TEMPLATE "${CONNECT_DB_NAME}"" >/dev/null 2>&1
    sleep 3
    echo -en '\e[8;15r\e[8H'
    if ! PGPASSWORD=$CONNECT_DB_PASS pg_restore -h ${CONNECT_DB_IP} -p ${CONNECT_DB_PORT} -U ${CONNECT_DB_USER} -e -w -v -j 4 -O -n public -d "$DB" "$RDB"; then
        echo -e "pg_restore: Error"
        echo -en '\e[r\e[6H'
        echo -e "Restore STATUS for Database '${DB}':"'\e[00;31m' "\033[5m FAILED \e[00m"
        echo -en '\e[r\e[16H'
        PGPASSWORD=$CONNECT_DB_PASS psql -h ${CONNECT_DB_IP} -p ${CONNECT_DB_PORT} -d ${CONNECT_DB_NAME} -U ${CONNECT_DB_USER} -w -c "DROP DATABASE \"$DB\"" >/dev/null 2>&1
        exit 1
    fi
    echo -e "pg_restore: Done"
    echo -en '\e[r\e[6H'
    echo -e "Restore STATUS for Database '${DB}':"'\e[00;32m'"\033[5m SUCCESS \e[00m"
    echo -en '\e[r\e[16H'
    echo -e " "
    mv "$TR"/"$FS" "$DATADIR"/"$DB"
    date2=$(date +"%s")
    diff=$(($date2-$date1))
    if [ $? -eq 0 ]; then
        RDBSIZE="$(du -h $RDB | awk '{print $1}')"
        DBSIZE=$(PGPASSWORD=$CONNECT_DB_PASS psql -h ${CONNECT_DB_IP} -p ${CONNECT_DB_PORT} -d ${CONNECT_DB_NAME} -U ${CONNECT_DB_USER} -w -tAc "SELECT pg_size_pretty(pg_database_size('$DB'))")
        echo -e "Database Dump '$(basename $RDB)' Size: ${RDBSIZE}B"
        echo -e "Database Restored '${DB}' Size: $DBSIZE"
        echo -e "Time taken for restore: $(($diff / 60)) minutes and $(($diff % 60)) seconds"
    fi
    rm -rf $TR
}

_status() {
    start-stop-daemon --status --quiet --pidfile $PIDFILE
    return $?
}

case "${1}" in
    start)
    printf '%70s\n' | tr ' ' -
    echo -n "Starting ${NAME}: "
    _start_loglevel
    start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
    --chuid ${USER} --background --make-pidfile \
    --chdir ${CHDIR} --exec ${VIRTENV} ${DAEMON} -- ${DAEMON_START}
    _check_pid
    _postcheck
    printf '%70s\n' | tr ' ' -
    echo -e "\n"
    ;;

    status)
    printf '%70s\n' | tr ' ' -
    _status && echo "running" || echo "stopped"
    printf '%70s\n' | tr ' ' -
    echo -e "\n"
    ;;

    startdump)
    clear
    printf '%70s\n' | tr ' ' -
    echo -e " "
    echo -n "Starting ${NAME} with option workers=0 : "
    start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
    --chuid ${USER} --background --make-pidfile \
    --chdir ${CHDIR} --exec ${VIRTENV} ${DAEMON} -- ${DAEMON_DUMPSTART}
    _check_pid
    _postcheck
    printf '%70s\n' | tr ' ' -
    echo -e "\n"
    ;;

    stop)
    printf '%70s\n' | tr ' ' -
    echo -n "Stopping ${NAME}: "
    sleep 5
    start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile ${PIDFILE} --oknodo --exec ${VIRTENV} ${DAEMON}
    _postcheck
    printf '%70s\n' | tr ' ' -
    echo -e "\n"
    ;;

    restart)
    printf '%70s\n' | tr ' ' -
    echo -n "Restarting ${NAME}: "
    _start_loglevel
    _check_pid
    _restart
    _postcheck
    printf '%70s\n' | tr ' ' -
    echo -e "\n"
    ;;

    update)
    clear
    printf '%70s\n' | tr ' ' -
    echo -e " "
    echo -en "Updating ${NAME} with database '${DB}': "
    _check_db
    _update
    _postcheck
    printf '%70s\n' | tr ' ' -
    echo -e "\n"
    ;;

    clear)
    clear
    printf '%70s\n' | tr ' ' -
    echo -e " "
    echo -en "Checking connections for database '${DB}': "
    _check_db
    _session_clear
    printf '%70s\n' | tr ' ' -
    echo -e "\n"
    ;;

    drop)
    clear
    printf '%70s\n' | tr ' ' -
    echo -e " "
    echo -en "Checking database '${DB}' to Drop: "
    _check_db
    #echo -e '\e[00;32m' "\033[5m OK \e[00m"
    #echo -e " "
    _drop_db
    printf '%70s\n' | tr ' ' -
    echo -e "\n"
    ;;

    dump)
    clear
    printf '%70s\n' | tr ' ' -
    echo -e " "
    echo -en "Preparing database '${DB}' for dump: "
    _check_db
    _dump_db
    printf '%70s\n' | tr ' ' -
    echo -e "\n"
    ;;

    restore)
    clear
    printf '%70s\n' | tr ' ' -
    echo -e " "
    echo -en "Preparing database '${DB}' for restore: "
    _restore_db
    echo " "
    printf '%70s\n' | tr ' ' -
    echo -e "\n"
    ;;

    *)
    echo -e " "
    echo "Usage: ${NAME} <options>"
    echo ""
    echo "  start                  # Start the odoo-daemon"
    echo "  start <log-levels>     # Where log-level=info, debug_rpc, warn, test, critical, debug_sql, error, debug, debug_rpc_answer, notset"
    echo "  startdump              # Start the odoo-daemon with worker=0"
    echo "  stop                   # Stop the odoo-daemon"
    echo "  status                 # Running Status of odoo-daemon"
    echo "  restart                # Restart the odoo-daemon"
    echo "  restart <log-levels>   # Where log-level=info, debug_rpc, warn, test, critical, debug_sql, error, debug, debug_rpc_answer, notset"
    echo "  update <database name> # Run -u all on the database"
    echo "  update all             # Run -u all on all the available databases"
    echo "  clear <database name>  # Terminate the connections to the database"
    echo "  dump <database name> </output directory/filename.dump> # dump the database. Provide options."
    echo "  restore <new database name> </path to database/filename.dump|.tar.gz> # If given filename ends with .dump it consider without filestore, else if ends with .tar.gz, it consider with filestore"
    echo "  drop <database name>   # Drop the database and filestore"
    echo -e "\n"
    exit 1
    ;;

esac
exit 0
