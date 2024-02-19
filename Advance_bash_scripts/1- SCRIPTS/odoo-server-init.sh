#!/bin/bash
#
# AUTHOR:                       John Britto
# PROFESSION:                   System Administrator
# SCRIPT DATE:                  03-Mar-2014
# COPYRIGHTS:                   Sodexis inc.

#changelog:
# v1: remvoed the restart after -u all.
# v1.1: added exclud_table  and exclude_table_data  during pg_dump.
### BEGIN INIT INFO
# Provides:                     odoo-server
# Required-Start:               sudo /etc/init.d/odoo-server start
# Required-Stop:                sudo /etc/init.d/odoo-server stop
# Required Postgres role:       root [CREATE ROLE root WITH LOGIN;]
# Should-Started:                       $network
# Should-Stop:                          $network
# Default-Start:                        2 3 4 5
# Default-Stop:                         0 1 6
# Short-Description:                    Enterprise Resource Management software
# Description:                          Open ERP is a complete ERP and CRM software.
### END INIT INFO

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

PATH=/bin:/sbin:/usr/bin
DAEMON=/opt/odoo/8.0/odoo.py
CHDIR=/opt/odoo/8.0/
NAME=odoo-server
DESC=odoo-server
CHECK_PSQL="$(which psql)"
# Specify the user name (Default: odoo).
USER=`ls -ld /opt/odoo | awk '{print $3}'`

# Specify an alternate config file (Default: /etc/odoo-server.conf).
CONFIGPATH="/etc/odoo-server.conf"

#DB restore credential
DBUSER=`cat "$CONFIGPATH" |grep db_user |awk '{print $3}'`
PGPASS=`cat "$CONFIGPATH" |grep db_password |awk '{print $3}'`

if [ -z "$CHECK_PSQL" ]; then
	echo " "
	echo -e '\e[00;31m'"\033[5m ERRORS \e[00m"
	echo -e "The Script Could not find PSQL binaries. See if it is installed."
	echo -e "Install using: sudo apt-get install postgresql-client-9.3 "
	echo -e "Aborting..""\n"
    echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
    exit 1
fi

# Database Specific
DB=$2
RDB=$3
EXCLUDE_TABLE=no
EXCLUDE_TABLE_DATA="--exclude-table-data=ir_attachment --exclude-table-data=message_attachment_rel --exclude-table-data=mail_compose_message_ir_attachments_rel --exclude-table-data=email_template_attachment_rel"
PGCLUSTER="$(which pg_lsclusters)"
DB_PORT=5432

# Log Level
LOG_LEVEL="info debug_rpc warn test critical debug_sql error debug debug_rpc_answer notset"
CASE=$1
CHECK_LOG_LEVEL=$2
ERRORS=$3
LOG=/var/log/odoo/odoo-server.log
WORK="$(grep 'workers' $CONFIGPATH)"

CONFNAME=odoo-server.conf
GREPPROCESS="$(echo "$CONFNAME" | sed 's/./[\0]/')"
COUNTPROCESS=`ps aux |grep "$GREPPROCESS"| wc -l`

#To check if openerp is already run by eclipse
ECLICONFNAME=org.python.pydev
ECLIGREP="$(echo "$ECLICONFNAME" | sed 's/./[\0]/')"
ECLICOUNT=`ps aux |grep "$ECLIGREP"| wc -l`

# Additional options that are passed to the Daemon.
DAEMON_START="-c $CONFIGPATH --logfile=${LOG}"
DAEMON_DUMPSTART="-c $CONFIGPATH --logfile=${LOG} --workers=0"
DAEMON_UPDATE="-c $CONFIGPATH --logfile=${LOG} --workers=0 -d $DB -u all"
UPDATEINSEC="1200"
UPDATEINMIN=$(($UPDATEINSEC / 60))
UPDATE_TMP_LOG=/opt/support_files/scripts/logs/${DB}-u-all.log
UPDATE_CONTEXT="Computing parent left and right for table ir_ui_menu..."

#Very important. for start-stop-daemon to start/stop odoo-server.
PIDFILE=/var/run/$NAME.pid
#pid=`cat $PIDFILE`

#=====================END OF VARIABLES==================

check_cluster() {
declare -a CLUSTERPORT=(`$PGCLUSTER -h | awk '{print $3}'`)
if [ `"$PGCLUSTER" -h | wc -l` -gt "1" ]; then
	echo "There are multiple clusters found in the server as follow:-"
	$PGCLUSTER
	for PORT in "${CLUSTERPORT[@]}"
    do
    echo
    echo -n "Enter the Port number of the cluster you would like to connect: "
	read PORTIN
	echo
    if [[ "$PORT" = "$PORTIN" ]]; then
        DB_PORT=$PORTIN
        break
    else
        echo
        echo -n "The given port is"
        echo -e '\e[00;31m'"\033[5m WRONG \e[0m"
        echo
    fi
    done
fi
}

if [ ! -d /var/log/odoo ]; then
	mkdir -p /var/log/odoo
	chown ${USER}: /var/log/odoo
fi
if [ ! -d /opt/support_files/scripts/logs ]; then
	mkdir -p /opt/support_files/scripts/logs
	chown ${USER}: /opt/support_files/scripts/logs
fi

declare -a DBNAME=(`su - postgres -c "psql -d postgres --port=$DB_PORT --tuples-only -P format=unaligned -c \"SELECT datname FROM pg_database JOIN pg_authid ON pg_database.datdba = pg_authid.oid WHERE rolname = '$DBUSER'\""`)
DBN=`su - postgres -c "psql -d postgres --port=$DB_PORT --tuples-only -P format=unaligned -c \"SELECT datname FROM pg_database JOIN pg_authid ON pg_database.datdba = pg_authid.oid WHERE rolname = '$DBUSER'\""`


sessionclear() {
        echo -e "The Running sessions are:"
        echo -e " "
# Needed to use here docments below because Database with superuser privilage can only show other db sessions.
# and superuser can only terminate other user DB sessions. Within EOF (Here documents), indentation should not be made. otherwise EOF wont work.
su - postgres <<EOF
psql --port=$DB_PORT -c "SELECT datid,datname,pid,usename,waiting,state,query FROM pg_stat_activity WHERE pg_stat_activity.datname = '$DB'"
EOF
    read -p "Do you need to close the sessions [y/n]?" char
	echo -e " "
	case "$char" in
		y|Y )
su - postgres <<EOF1
psql --port=$DB_PORT -q -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$DB' AND pid <> pg_backend_pid()"
if [ "$?" -eq "0" ]; then
echo -e "Clearning sessions for '${DB}':\e[00;32m \033[5m SUCCESS \e[00m"
else
echo -e "Clearning sessions for '${DB}':\e[00;31m \033[5m FAILED \e[00m"
fi
EOF1
        ;;
        n|N )
			echo -e '\e[00;32m'"\033[5m CANCELLED \e[00m"
		;;
        * ) echo "Invalid Input, press y/n"
        ;;
    esac
}

dropdb() {
    echo -e "Clearning the running sessions..."
    echo -e " "
su - postgres <<EOF
psql -d postgres --port=$DB_PORT -q -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$DB' AND pid <> pg_backend_pid()"
if [ "$?" -eq "0" ]; then
echo -e "Clearning sessions for '${DB}':\e[00;32m \033[5m SUCCESS \e[00m"
else
echo -e "Clearning sessions for '${DB}':\e[00;31m \033[5m FAILED \e[00m"
fi
EOF
    echo -e " "
    echo -n "Droping the database '${DB}'"
su - postgres <<EOF
psql -d postgres --port=$DB_PORT -q -c "DROP DATABASE \"$DB\""
sleep 5
EOF
if [ -z `psql -d postgres --port=$DB_PORT -tAc "SELECT 1 FROM pg_database WHERE datname = '$DB'"` ] && [ "$DB" != "all" ]; then
echo -e '\e[00;32m'"\033[5m SUCCESS \e[00m"
else
echo -e '\e[00;31m' "\033[5m FAILED \e[00m"
fi
}

checkdaemon() {
	if [ ! -x $DAEMON -o ! -f $CONFIGPATH ]; then
        echo -e '\e[00;31m' "\033[5m ERRORS \e[00m"
        echo -e " "
        echo -e "Check if daemon script exist and its executable."
        echo -e "Check if config file exist and its regular file."
        echo -e "Check the variable DAEMON, CONFIGPATH PATH in script"
        echo -e " "
        echo -e "No changes made to ${NAME}.""\n"
        echo -e "Aborting.."
		echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
		echo -e "\n"
    exit 1
    fi
}

checkpid() {
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
            echo -e "$(yes '"' | head -45 | paste -s -d '' -)"
            echo -e "$(pgrep -lf "$GREPPROCESS")"
            echo -e "\n"
            echo -e "To KILL, use cmd:"
            echo -e "$(yes '"' | head -18 | paste -s -d '' -)"
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
		echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
		echo -e "\n"
    exit 1
    fi
}

dbcheck() {
	if [ -z `psql -d postgres --port=$DB_PORT -tAc "SELECT 1 FROM pg_database WHERE datname = '$DB'"` ] && [ "$DB" != "all" ]; then
		echo -e '\e[00;31m'"\033[5m DATABASE NOT EXIST \e[0m"
		echo -e " "
		echo -e "Check spell, Upper/Lower case character of database name and try again."
		echo -e " "
		echo -e "The Available Databases are:-"
		echo -e "$(yes '"' | head -28 | paste -s -d '' -)"
		echo -e "$DBN" | sed "s/^/   /"
		echo -e " "
		echo -e "No changes made to ${NAME}."
		echo -e "Aborting.."
		echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
		echo -e "\n"
	exit 1
	fi
}

preproc() {
    #To add [] around the 1st character of a process to avoid grep own process
    if [ "$COUNTPROCESS" -ge "1" ]; then
        ST="WARNING"
        echo -e "\e[00;33m \033[5m $ST \e[00m"
        echo -e " "
        echo -e "Already $COUNTPROCESS Instance of ${NAME} running"
        echo -e "Try Closing it with cmd: $DESC stop."
        echo -e "Else, Try cmd: killall $DESC"
        echo -e "No changes made to ${NAME}.""\n"
        echo -e "Aborting.."
		echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
		echo -e "\n"
    exit 1
    fi
}

readchoice() {
	read -p "Do you want to send kill term to the PIDS [y/n]?" char
	echo -e " "
	echo -n "Stopping ${NAME} & Eclipse Process PID kill: "
		case "$char" in
		y|Y )
			for i in $(pgrep -lf "$ECLIGREP" | awk '{print $1}')
			do
				kill -9 $i > /dev/null 2>&1
				#echo -e "kill -9 $i"
			done
			ECLICOUNT=`ps aux |grep "$ECLIGREP"| wc -l`
			if [ "$ECLICOUNT" -eq "0" ]; then
				echo -e '\e[00;32m'"\033[5m SUCCESS \e[00m"
			else
				echo -e '\e[00;31m' "\033[5m FAILED $ST \e[00m"
				echo -e " "
				echo -e "There is some error, Contact admin"
				echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
				echo -e "\n"
				exit 1
			fi
        ;;
        n|N )
			echo -e '\e[00;32m'"\033[5m CANCELLED \e[00m"
			echo -e " "
			echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
			echo -e "\n"
			exit 1
		;;
        * ) echo "Invalid Input, press y/n"
        ;;
        esac
}

preprocst() {
    if [ "$COUNTPROCESS" -eq "0" -a "$ECLICOUNT" -eq "0" ]; then
        ST="ALREADY STOPPED"
        echo -e '\e[00;32m'"\033[5m $ST \e[00m"
        echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
        echo -e "\n"
    exit 1
    fi
    if [ "$COUNTPROCESS" -eq "0" -a "$ECLICOUNT" -ge "1" ]; then
        echo -e "\e[00;33m \033[5m WARNING \e[00m"
        echo -e " "
        echo -e "This script found $ECLICOUNT process of ${NAME} started by eclipse were running."
        echo -e " "
        echo -e "The Running Instance are:-"
        echo -e "$(yes '"' | head -27 | paste -s -d '' -)"
        echo -e "$(pgrep -lf "$ECLIGREP"|colrm 205)"
        echo -e "\n"
        readchoice
    elif [ "$COUNTPROCESS" -ge "1" -a "$ECLICOUNT" -eq "0" ]; then
    start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \
        --oknodo

    elif [ "$COUNTPROCESS" -ge "1" -a "$ECLICOUNT" -ge "1" ]; then
    start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \
        --oknodo
        echo -e "\e[00;33m \033[5m WARNING \e[00m"
        echo -e " "
        echo -e "This script found $ECLICOUNT process of ${NAME} started by eclipse were running."
        echo -e " "
        echo -e "The Running Instance are:-"
        echo -e "$(yes '"' | head -27 | paste -s -d '' -)"
        echo -e "$(pgrep -lf "$ECLIGREP"|colrm 205)"
        echo -e "\n"
    readchoice
    fi
}

logcheck() {
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
		echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
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
			echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
			echo -e "\n"
			exit 1
        fi
    else
        DAEMON_START="-c $CONFIGPATH --logfile=${LOG}"
    fi
}

restrt() {
	ps aux |grep "$GREPPROCESS" >/dev/null
	if [ $? -eq 0 ]; then
		start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \
        --oknodo

        sleep 1

        start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
        --chuid ${USER} --background --make-pidfile \
        --chdir ${CHDIR} --exec ${DAEMON} -- ${DAEMON_START}
    else
		sleep 1

        start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
        --chuid ${USER} --background --make-pidfile \
        --chdir ${CHDIR} --exec ${DAEMON} -- ${DAEMON_START}
    fi
}


updt() {
    ps aux |grep "$GREPPROCESS" >/dev/null
    if [ $? -eq 0 ]; then
        start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \
        --oknodo
        sleep 10
        ps aux |grep "$GREPPROCESS" >/dev/null
        if [ $? -eq 0 ]; then
            echo -e '\e[r\e[3H'
            echo -e "Updating ${DESC} with '${DB}': "'\e[00;31m'"\033[5m ERRORS \e[00m"
            echo -e " "
            echo -e "Stopping of ${NAME} failed.."
            echo -e " "
            echo -e "The Running Instance are:-"
            echo -e "$(yes '"' | head -27 | paste -s -d '' -)"
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
                echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
                echo -e "\n"
                exit 1
            else
                echo -e '\e[00;32m'"\033[5m SUCCESS \e[00m"
            fi
        fi
        #echo -en '\e[r\e[2H'
        if [ "$DB" == "all" ]; then
            for DBI in ${!DBNAME[*]}
            do
                DAEMON_UPDATE_ALL="-c $CONFIGPATH --logfile=${LOG} --workers=0 -d ${DBNAME[$DBI]} -u all"
                echo -e " "
                echo -e "Updating ${DESC} with '${DBNAME[$DBI]}': "'\e[00;32m'"\033[5m UPDATE IN PROGRESS... \e[00m"
                start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
                --chuid ${USER} --background --make-pidfile \
                --chdir ${CHDIR} --exec ${DAEMON} -- ${DAEMON_UPDATE_ALL}
                echo -e " "
                echo -n "Waiting for Database Update status: "
                /usr/bin/timeout $UPDATEINSEC sed "/$UPDATE_CONTEXT/q" > "$UPDATE_TMP_LOG" < <(tail -fn0 "$LOG")
                if [ "$?" -eq "124" ]; then
                    echo -e '\e[00;31m'"\033[5m UNKNOWN \e[00m"
                    echo -e " "
                    echo -e "It seems Database update is hanged. This script waited $UPDATEINMIN minutes and could not find \e[4m ${NAME} is running/ waiting for connection \e[00m written state from the logs."
                    sleep 10
                    start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \
                    --oknodo
                elif grep -oq 'ERROR' $UPDATE_TMP_LOG; then
                    echo -e '\e[00;33m'"\033[5m DONE with Errors \e[00m"
                    sleep 10
                    start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \
                    --oknodo
                else
                    echo -e '\e[00;32m'"\033[5m DONE \e[00m"
                    sleep 10
                    start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \
                    --oknodo
                fi
            done
            echo -e " "
            echo -e "Updating ${DESC} with ALL Available Databases Completed"
            echo -e " "
            echo -e "${NAME} will be stopped now and started with $WORK"
            echo -e " "
            echo -n "Starting ${DESC}: "
            sleep 5
            start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \
            --oknodo
            sleep 3
            start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
            --chuid ${USER} --background --make-pidfile \
            --chdir ${CHDIR} --exec ${DAEMON} -- ${DAEMON_START}
        else
            echo -en "Updating ${DESC} with '${DB}': "
            echo -e '\e[00;32m'"\033[5m UPDATE IN PROGRESS... \e[00m"
            start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
            --chuid ${USER} --background --make-pidfile \
            --chdir ${CHDIR} --exec ${DAEMON} -- ${DAEMON_UPDATE}
            echo -e " "
            echo -e "Check the logs..."
            echo -e " "
            echo -n "Waiting for Database Update status: "
            /usr/bin/timeout $UPDATEINSEC sed "/$UPDATE_CONTEXT/q" > "$UPDATE_TMP_LOG" < <(tail -fn0 "$LOG")
            if [ "$?" -eq "124" ]; then
                echo -e '\e[00;31m'"\033[5m UNKNOWN \e[00m"
                echo -e " "
                echo -e "It seems Database update is taking too long. This script waited $UPDATEINMIN minutes and could not find \e[4m ${NAME} is running/ waiting for connection \e[00m written state from the logs."
                echo -e "Check the log to see if the update is still ON."
                echo -e " "
                echo -e "NOTE: ${NAME} is running with single process mode. run the daemon with stop and start again."
                echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
                echo -e "\n"
                exit 1
            elif grep -oq 'ERROR' $UPDATE_TMP_LOG; then
                echo -e '\e[00;33m'"\033[5m DONE with Errors \e[00m"
                echo -e " "
                echo -e "${NAME} will be stopped now and started with $WORK"
                echo -e " "
                echo -n "Starting ${DESC}: "
                sleep 10
                start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \
                --oknodo
                sleep 3
                start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
                --chuid ${USER} --background --make-pidfile \
                --chdir ${CHDIR} --exec ${DAEMON} -- ${DAEMON_START}
            else
                echo -e '\e[00;32m'"\033[5m DONE \e[00m"
                echo -e " "
                echo -e "${NAME} will be stopped now and started with $WORK"
                echo -e " "
                echo -n "Starting ${DESC}: "
                sleep 10
                start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \
                --oknodo
                sleep 3
                start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
                --chuid ${USER} --background --make-pidfile \
                --chdir ${CHDIR} --exec ${DAEMON} -- ${DAEMON_START}
            fi
        fi
    else
        if [ "$DB" == "all" ]; then
            for DBI in ${!DBNAME[*]}
            do
                DAEMON_UPDATE_ALL="-c $CONFIGPATH --logfile=${LOG} --workers=0 -d ${DBNAME[$DBI]} -u all"
                echo -e " "
                echo -e "Updating ${DESC} with '${DBNAME[$DBI]}': "'\e[00;32m'"\033[5m UPDATE IN PROGRESS... \e[00m"
                start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
                --chuid ${USER} --background --make-pidfile \
                --chdir ${CHDIR} --exec ${DAEMON} -- ${DAEMON_UPDATE_ALL}
                echo -e " "
                echo -n "Waiting for Database Update status: "
                /usr/bin/timeout $UPDATEINSEC sed "/$UPDATE_CONTEXT/q" > "$UPDATE_TMP_LOG" < <(tail -fn0 "$LOG")
                if [ "$?" -eq "124" ]; then
                    echo -e '\e[00;31m'"\033[5m UNKNOWN \e[00m"
                    echo -e " "
                    echo -e "It seems Database update is taking too long. This script waited $UPDATEINMIN minutes and could not find \e[4m ${NAME} is running/ waiting for connection \e[00m written state from the logs."
                    echo -e "Check the log to see if the update is still ON."
                    echo -e " "
                    echo -e "NOTE: ${NAME} is running with single process mode. run the daemon with stop and start again."
                    echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
                    echo -e "\n"
                    exit 1
                elif grep -oq 'ERROR' $UPDATE_TMP_LOG; then
                    echo -e '\e[00;33m'"\033[5m DONE with Errors \e[00m"
                    sleep 10
                    start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \
                    --oknodo
                else
                    echo -e '\e[00;32m'"\033[5m DONE \e[00m"
                    sleep 10
                    start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \
                    --oknodo
                fi
            done
            echo -e " "
            echo -e "Updating ${DESC} with ALL Available Databases Completed"
            echo -e " "
            echo -e "openerp-server will be stopped now and started with $WORK"
            echo -e " "
            echo -n "Starting ${DESC}: "
            sleep 5
            start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \
            --oknodo
            sleep 3
            start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
            --chuid ${USER} --background --make-pidfile \
            --chdir ${CHDIR} --exec ${DAEMON} -- ${DAEMON_START}
        else
            echo -en "Updating ${DESC} with '${DB}': "
            echo -e '\e[00;32m'"\033[5m UPDATE IN PROGRESS... \e[00m"
            start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
            --chuid ${USER} --background --make-pidfile \
            --chdir ${CHDIR} --exec ${DAEMON} -- ${DAEMON_UPDATE}
            echo -e " "
            echo -e "Check the logs..."
            echo -e " "
            echo -n "Waiting for Database Update status: "
            /usr/bin/timeout $UPDATEINSEC sed "/$UPDATE_CONTEXT/q" > "$UPDATE_TMP_LOG" < <(tail -fn0 "$LOG")
            if [ "$?" -eq "124" ]; then
                echo -e '\e[00;31m'"\033[5m UNKNOWN \e[00m"
                echo -e " "
                echo -e "It seems Database update is taking too long. This script waited $UPDATEINMIN minutes and could not find \e[4m ${NAME} is running/ waiting for connection \e[00m written state from the logs."
                echo -e "Check the log to see if the update is still ON."
                echo -e " "
                echo -e "NOTE: ${NAME} is running with single process mode. run the daemon with stop and start again."
                echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
                echo -e "\n"
                exit 1
            elif grep -oq 'ERROR' $UPDATE_TMP_LOG; then
                echo -e '\e[00;33m'"\033[5m DONE with Errors \e[00m"
                echo -e " "
                echo -e "${NAME} will be stopped now and started with $WORK"
                echo -e " "
                echo -n "Starting ${DESC}: "
                sleep 10
                start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \
                --oknodo
                sleep 3
                start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
                --chuid ${USER} --background --make-pidfile \
                --chdir ${CHDIR} --exec ${DAEMON} -- ${DAEMON_START}
            else
                echo -e '\e[00;32m'"\033[5m DONE \e[00m"
                echo -e " "
                echo -e "${NAME} will be stopped now and started with $WORK"
                echo -e " "
                echo -n "Starting ${DESC}: "
                sleep 10
                start-stop-daemon --stop --quiet --pidfile ${PIDFILE} \
                --oknodo
                sleep 3
                start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
                --chuid ${USER} --background --make-pidfile \
                --chdir ${CHDIR} --exec ${DAEMON} -- ${DAEMON_START}
            fi
        fi
    fi
}

postproc() {
    if [ "$CASE" == "start" -a -z "$CHECK_LOG_LEVEL" ]; then
        ST="STARTED"
        sleep 5
        ps aux |grep "$GREPPROCESS" >/dev/null
        if [ $? -eq 0 ]; then
            echo -e '\e[00;32m'"\033[5m $ST \e[00m with $WORK"
        else
            echo -e '\e[00;31m' "\033[5m NOT $ST \e[00m"
        fi
    elif [ "$CASE" == "start" -a ! -z "$CHECK_LOG_LEVEL" ]; then
        ST="STARTED wth Log-level = $CHECK_LOG_LEVEL"
        sleep 5
        ps aux |grep "$GREPPROCESS" >/dev/null
        if [ $? -eq 0 ]; then
            echo -e '\e[00;32m'"\033[5m $ST \e[00m"
        else
            echo -e '\e[00;31m' "\033[5m NOT $ST \e[00m"
        fi
    elif [ "$CASE" == "restart" -a -z "$CHECK_LOG_LEVEL" ]; then
        ST="RESTARTED"
        sleep 5
        ps aux |grep "$GREPPROCESS" >/dev/null
        if [ $? -eq 0 ]; then
            echo -e '\e[00;32m'"\033[5m $ST \e[00m with $WORK"
        else
            echo -e '\e[00;31m' "\033[5m NOT $ST \e[00m"
        fi
    elif [ "$CASE" == "restart" -a ! -z "$CHECK_LOG_LEVEL" ]; then
        ST="RESTARTED wth Log-level = $CHECK_LOG_LEVEL"
        sleep 5
        ps aux |grep "$GREPPROCESS" >/dev/null
        if [ $? -eq 0 ]; then
            echo -e '\e[00;32m'"\033[5m $ST \e[00m"
        else
            echo -e '\e[00;31m' "\033[5m NOT $ST \e[00m"
        fi
    elif [ "$CASE" == "update" ]; then
        ST="STARTED"
        sleep 5
        ps aux |grep "$GREPPROCESS" >/dev/null
        if [ $? -eq 0 ]; then
            echo -e '\e[00;32m'"\033[5m $ST \e[00m"
        else
            echo -e '\e[00;31m' "\033[5m NOT $ST \e[00m"
        fi
    elif [ "$CASE" == "startdump" ]; then
        ST="STARTED"
        sleep 5
        ps aux |grep "$GREPPROCESS" >/dev/null
        if [ $? -eq 0 ]; then
            echo -e '\e[00;32m'"\033[5m $ST with worker=0 \e[00m"
        else
            echo -e '\e[00;31m' "\033[5m NOT $ST \e[00m"
        fi
    elif [ "$CASE" == "stop" ]; then
        ST="STOPPED"
        sleep 5
        ps aux |grep "$GREPPROCESS" >/dev/null
        if [ $? -eq 0 ]; then
            echo -e '\e[00;31m' "\033[5m NOT $ST \e[00m"
            echo " "
            T1=$(ps aux |grep "$GREPPROCESS")
            echo -e "Running $COUNTPROCESS instances are as follow:-"
            echo " "
            echo "$T1"
        else
            echo -e '\e[00;32m'"\033[5m $ST \e[00m"
        fi
    else
        echo " "
    fi
}

dumpdb () {
	PGOUT=$(basename $RDB)
	RDBDIR=$(dirname $RDB)
	if [ ! -d "$RDBDIR" ]; then
		echo -e '\e[00;31m' "\033[5m ERROR \e[00m"
		echo " "
		echo -e "The dump output directory $RDBDIR, does not exists."
		echo " "
		echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
		echo -e "\n"
		exit 1
	elif [ -f "$RDB" ]; then
		echo -e '\e[00;31m' "\033[5m ERROR \e[00m"
		echo " "
		echo -e "The Dump output file name in Path: $RDB is already exists. Please give any other Dump output file name."
		echo " "
		echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
		echo -e "\n"
		exit 1
	else
		echo -e '\e[00;32m'"\033[5m OK \e[00m"
		PGOUT=$(basename $RDB)
		RDBDIR=$(dirname $RDB)
	fi
	echo -e "\n"
    echo -en "Dump STATUS for Database '${DB}' with exclude-table=${EXCLUDE_TABLE}: "
su - postgres <<EOF2
sleep 3
if [ "$EXCLUDE_TABLE" = "yes" ]; then

echo -en '\e[8;15r\e[8H'
if ! pg_dump -Fc -v -O -x ${EXCLUDE_TABLE_DATA} "$DB" > "$PGOUT"; then
echo -e "pg_dump: Error"
echo -en '\e[r\e[6H'
echo -e "Dump STATUS for Database '${DB}' with exclude-table=${EXCLUDE_TABLE}:"'\e[00;31m' "\033[5m FAILED \e[00m"
echo -en '\e[r\e[16H'
echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
echo -e "\n"
exit 1
fi

else

echo -en '\e[8;15r\e[8H'
if ! pg_dump -Fc -v -O -x "$DB" > "$PGOUT"; then
echo -e "pg_dump: Error"
echo -en '\e[r\e[6H'
echo -e "Dump STATUS for Database '${DB}' with exclude-table=${EXCLUDE_TABLE}:"'\e[00;31m' "\033[5m FAILED \e[00m"
echo -en '\e[r\e[16H'
echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
echo -e "\n"
exit 1
fi

fi
EOF2
echo -e "pg_dump: Done"
PG_DIR=$(getent passwd postgres | cut -d: -f6 )
mv $PG_DIR/$PGOUT $RDBDIR/
echo -en '\e[r\e[6H'
echo -e "Dump STATUS for Database '${DB}' with exclude-table=${EXCLUDE_TABLE}:"'\e[00;32m'"\033[5m SUCCESS \e[00m"
echo -en '\e[r\e[16H'
echo -e " "
echo -e "Dump-Size    Dump-Location"
du -hs $RDB
echo -e " "
}


restoredb () {
	if [[ ! -z `psql -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$DB'"` ]]; then
		echo -e '\e[00;31m' "\033[5m ERROR \e[00m"
		echo " "
		echo -e "The Database name already Exists."
		echo " "
		echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
		echo -e "\n"
	exit 1
	fi
	if [ ! -f "$RDB" ]; then
		echo -e '\e[00;31m' "\033[5m ERROR \e[00m"
		echo " "
		echo -e "$RDB Does Not Exists. Check path,permission."
		echo " "
		echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
		echo -e "\n"
	exit 1
	fi
	echo -e '\e[00;32m'"\033[5m OK \e[00m"
	echo -e "\n"
    echo -en "Restore STATUS for Database '${DB}': "
    date1=$(date +"%s")
su - postgres <<EOF3
psql -d postgres --port=$DB_PORT -q -c "CREATE DATABASE \"$DB\" WITH OWNER $DBUSER"
sleep 3
echo -en '\e[8;15r\e[8H'
if ! PGPASSWORD=$PGPASS pg_restore -U "$DBUSER" -h localhost -e -w -v -j 4 -O -x -d "$DB" "$RDB"; then
echo -e "pg_restore: Error"
echo -en '\e[r\e[6H'
echo -e "Restore STATUS for Database '${DB}':"'\e[00;31m' "\033[5m FAILED \e[00m"
echo -en '\e[r\e[16H'
psql -d postgres --port=$DB_PORT -c "DROP DATABASE \"$DB\"" >/dev/null 2>&1
exit 1
else
echo -e "pg_restore: Done"
echo -en '\e[r\e[6H'
echo -e "Restore STATUS for Database '${DB}':"'\e[00;32m'"\033[5m SUCCESS \e[00m"
echo -en '\e[r\e[16H'
echo -e " "
fi
EOF3
PGOUT=$(basename $RDB)
date2=$(date +"%s")
diff=$(($date2-$date1))
if [ $? -eq 0 ]; then
	RDBSIZE="$(du -h $RDB | awk '{print $1}')"
	DBSIZE="$(psql -d postgres --port=$DB_PORT -tAc "SELECT pg_size_pretty(pg_database_size('$DB'))")"
	echo -e "Database Dump '${PGOUT}' Size: ${RDBSIZE}B"
	echo -e "Database Restored '${DB}' Size: $DBSIZE"
	echo -e "Time taken for restore: $(($diff / 60)) minutes and $(($diff % 60)) seconds"
fi
}


case "${1}" in
    start)
    clear
    echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
    echo -e " "
    echo -n "Starting ${DESC}: "
    checkdaemon
    preproc
    logcheck

    start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
    --chuid ${USER} --background --make-pidfile \
    --chdir ${CHDIR} --exec ${DAEMON} -- ${DAEMON_START}

    checkpid
    postproc
    echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
    echo -e "\n"
    ;;

    startdump)
    clear
    echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
    echo -e " "
    echo -n "Starting ${DESC} with option workers=0 : "
    checkdaemon
    preproc

    start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
    --chuid ${USER} --background --make-pidfile \
    --chdir ${CHDIR} --exec ${DAEMON} -- ${DAEMON_DUMPSTART}

    checkpid
    postproc
    echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
    echo -e "\n"
    ;;

    stop)
    clear
    echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
    echo -e " "
    echo -n "Stopping ${DESC}: "
    checkdaemon
    preprocst
    postproc
    echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
    echo -e "\n"
    ;;

    restart)
    clear
    echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
    echo -e " "
    echo -n "Restarting ${DESC}: "
    checkdaemon
    logcheck
    checkpid
    restrt
    postproc
    echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
    echo -e "\n"
    ;;

    update)
    clear
    echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
    echo -e " "
    checkdaemon
    check_cluster
    dbcheck
    updt
    postproc
    echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
    echo -e "\n"
    ;;

    clear)
    clear
    echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
    echo -e " "
    echo -en "Checking sessions for '${DB}': "
    dbcheck
    echo -e '\e[00;32m' "\033[5m IN PROGRESS... \e[00m"
    echo -e " "
    sessionclear
    echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
    echo -e "\n"
    ;;

    drop)
    clear
    echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
    echo -e " "
    echo -en "Checking DB '${DB}' to Drop: "
    dbcheck
    echo -e '\e[00;32m' "\033[5m OK \e[00m"
    echo -e " "
    dropdb
    echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
    echo -e "\n"
    ;;

    dump)
    clear
    echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
    echo -e " "
    check_cluster
    echo -en "Preparing DB '${DB}' for dump: "
    dbcheck
    dumpdb
    echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
    echo -e "\n"
    ;;

    restore)
    clear
    echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
    echo -e " "
    check_cluster
    echo -en "Preparing DB '${DB}' for restore: "
    restoredb
    echo " "
    echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
    echo -e "\n"
    ;;

    *)
    N=/etc/init.d/${NAME}
    echo -e " "
    echo "Usage: ${NAME} {start | start <Log-level> | startdump | stop | restart | restart <Log-level> | update <DB name> | update all | clear <DB name> | dump <DB NAME> <Path to backup DB with extention .dump | restore <DB name> <Path to read the restoring DB> | drop <dbname>}" >&2
    echo "Log-level: info, debug_rpc, warn, test, critical, debug_sql, error, debug, debug_rpc_answer, notset" >&2
    echo -e "\n"
    exit 1
    ;;

esac
exit 0
