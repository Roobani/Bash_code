#!/bin/bash
#
# AUTHOR:                       John Britto
# PROFESSION:                   System Administrator
# SCRIPT DATE:                  03-Mar-2014
# COPYRIGHTS:                   Sodexis inc.
### BEGIN INIT INFO
# Provides:                     openerp-server
# Required-Start:               sudo /etc/init.d/openerp-server start
# Required-Stop:                sudo /etc/init.d/openerp-server stop
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
        echo -e "No changes made to openerp-server.""\n"
        echo -e "Aborting..""\n"
        echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
        exit 1
fi

PATH=/bin:/sbin:/usr/bin
export PYTHONPATH=/opt/openerp/v7.0-git/
DAEMON=/opt/openerp/v7.0-git/openerp-server
CHDIR=/opt/openerp/v7.0-git/
CONNECTOR_NAME=prestashop-connector
CHECK_PRESTA=$2
PRESTA_DAEMON=/opt/openerp/v7.0/custom_modules/launchpad/openerp-connector/connector/openerp-connector-worker
PRESTA_LOG=/var/log/prestashop/prestashop-connector.log
PRESTA_CONFNAME=prestashop-connector.conf
PRESTA_GREPPROCESS="$(echo "$PRESTA_CONFNAME" | sed 's/./[\0]/')"
PRESTA_COUNTPROCESS=`ps aux |grep "$PRESTA_GREPPROCESS"| wc -l`
PRESTA_CONFIGPATH="/etc/prestashop-connector.conf"
PRESTA_WORK="$(grep 'workers' $PRESTA_CONFIGPATH)"

# Specify the user name (Default: openerp).
USER=`ls -ld /opt/openerp | awk '{print $3}'`

# Specify an alternate config file (Default: /etc/openerp-server.conf).
# Log Level
LOG_LEVEL="info debug_rpc warn test critical debug_sql error debug debug_rpc_answer notset"
CASE=$1
CHECK_LOG_LEVEL=$2
ERRORS=$3

# Additional options that are passed to the Daemon.
DAEMON_START="-c $PRESTA_CONFIGPATH"

PRESTA_PIDFILE=/var/run/$CONNECTOR_NAME.pid

checkdaemon() {
	if [ ! -x $PRESTA_DAEMON -o ! -f $PRESTA_CONFIGPATH ]; then
        echo -e '\e[00;31m' "\033[5m ERRORS \e[00m"
        echo -e " "
        echo -e "Check if daemon script exist and its executable."
        echo -e "Check if config file exist and its regular file."
        echo -e "Check the variable DAEMON, CONFIGPATH PATH in script"
        echo -e " "
        echo -e "No changes made to ${CONNECTOR_NAME}.""\n"
        echo -e "Aborting.."
		echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
		echo -e "\n"
    exit 1
    fi
}

checkpid() {
	sleep 5
	# Necessary to add the variable inside daemon to catch the correct value.
	PRESTA_PIDFILE=/var/run/$CONNECTOR_NAME.pid
	pid=`cat $PRESTA_PIDFILE`
    if [ ! -f $PRESTA_PIDFILE -o ! -d /proc/$pid ]; then
        echo -e '\e[00;31m' "\033[5m ERRORS \e[00m"
        echo -e " "
        echo -e "Running $PRESTA_PIDFILE could not found."
        if ps aux |grep "$PRESTA_GREPPROCESS" >/dev/null; then
			echo -e " "
			echo -e "This Script found NON daemon running Instance:-"
            echo -e "$(yes '"' | head -45 | paste -s -d '' -)"
            echo -e "$(pgrep -lf "$PRESTA_GREPPROCESS")"
            echo -e "\n"
            echo -e "To KILL, use cmd:"
            echo -e "$(yes '"' | head -18 | paste -s -d '' -)"
            for i in $(pgrep -lf "$PRESTA_GREPPROCESS" | awk '{print $1}')
            do
				echo -e "kill -9 $i"
            done
        fi
        echo -e " "
        echo -e "Try Starting the prestashop-connector again.."
        echo -e " "
        echo -e "No changes made to ${CONNECTOR_NAME}.""\n"
        echo -e "Aborting.."
		echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
		echo -e "\n"
    exit 1
    fi
}

preproc() {
    #To add [] around the 1st character of a process to avoid grep own process
    if [ "$PRESTA_COUNTPROCESS" -ge "1" ]; then
        ST="WARNING"
        echo -e "\e[00;33m \033[5m $ST \e[00m" 
        echo -e " "
        echo -e "Already $PRESTA_COUNTPROCESS Instance of prestashop-connector running"
        echo -e "Try Closing it with cmd: $CONNECTOR_NAME stop."
        echo -e "Else, Try cmd: killall $CONNECTOR_NAME"
        echo -e "No changes made to ${CONNECTOR_NAME}.""\n"
        echo -e "Aborting.."
		echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
		echo -e "\n"
     exit 1
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
        echo -e "Error: Log-Level given \e[4m$CHECK_LOG_LEVEL $ERRORS\e[0m does Not Match with any of OpenERP Log-Level!"
        echo -e " "
        echo -e "The Accepted log-levels are: info, debug_rpc, warn, test, critical, debug_sql, error, debug, debug_rpc_answer, notset"
        echo -e " "
        echo -e "No changes made to ${CONNECTOR_NAME}.""\n"
        echo -e "Aborting.."
        echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
        echo -e "\n"
    exit 1
    elif [ ! -z "$CHECK_LOG_LEVEL" -a -z "$ERRORS" ]; then
        if grep -qw "$CHECK_LOG_LEVEL" <<< "$LOG_LEVEL"; then
            DAEMON_START="-c $PRESTA_CONFIGPATH --log-level=$CHECK_LOG_LEVEL"
        else
            echo -e '\e[00;31m' "\033[5m ERRORS \e[00m"
            echo -e " "
            echo -e "Error: Log-Level given \e[4m$CHECK_LOG_LEVEL $ERRORS\e[0m does Not Match with any of OpenERP Log-Level!"
            echo -e " "
            echo -e "The Accepted log-levels are: info, debug_rpc, warn, test, critical, debug_sql, error, debug, debug_rpc_answer, notset"
            echo -e " "
            echo -e "No changes made to ${CONNECTOR_NAME}.""\n"
            echo -e "Aborting.."
            echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
            echo -e "\n"
        exit 1
        fi
    else
        DAEMON_START="-c $PRESTA_CONFIGPATH"
    fi
}

restrt() {
	ps aux |grep "$PRESTA_GREPPROCESS" >/dev/null
	if [ $? -eq 0 ]; then
		start-stop-daemon --stop --quiet --pidfile ${PRESTA_PIDFILE} \
        --oknodo
            
        sleep 1

        start-stop-daemon --start --quiet --pidfile ${PRESTA_PIDFILE} \
        --chuid ${USER} --background --make-pidfile \
        --chdir ${CHDIR} --exec ${PRESTA_DAEMON} -- ${DAEMON_START}
    else
		sleep 1

        start-stop-daemon --start --quiet --pidfile ${PRESTA_PIDFILE} \
        --chuid ${USER} --background --make-pidfile \
        --chdir ${CHDIR} --exec ${PRESTA_DAEMON} -- ${DAEMON_START}
    fi
}

postproc() {
    if [ "$CASE" == "start" -a -z "$CHECK_LOG_LEVEL" ]; then
        ST="STARTED"
        sleep 5
        ps aux |grep "$PRESTA_GREPPROCESS" >/dev/null
        if [ $? -eq 0 ]; then
            echo -e '\e[00;32m'"\033[5m $ST \e[00m with $PRESTA_WORK"
        else
            echo -e '\e[00;31m' "\033[5m NOT $ST \e[00m"
        fi
    elif [ "$CASE" == "start" -a ! -z "$CHECK_LOG_LEVEL" ]; then
        ST="STARTED wth Log-level = $CHECK_LOG_LEVEL"
        sleep 5
        ps aux |grep "$PRESTA_GREPPROCESS" >/dev/null
        if [ $? -eq 0 ]; then
            echo -e '\e[00;32m'"\033[5m $ST \e[00m"
        else
            echo -e '\e[00;31m' "\033[5m NOT $ST \e[00m"
        fi
    elif [ "$CASE" == "restart" -a -z "$CHECK_LOG_LEVEL" ]; then
        ST="RESTARTED"
        sleep 5
        ps aux |grep "$PRESTA_GREPPROCESS" >/dev/null
        if [ $? -eq 0 ]; then
            echo -e '\e[00;32m'"\033[5m $ST \e[00m with $PRESTA_WORK"
        else
            echo -e '\e[00;31m' "\033[5m NOT $ST \e[00m"
        fi
    elif [ "$CASE" == "restart" -a ! -z "$CHECK_LOG_LEVEL" ]; then
        ST="RESTARTED wth Log-level = $CHECK_LOG_LEVEL"
        sleep 5
        ps aux |grep "$PRESTA_GREPPROCESS" >/dev/null
        if [ $? -eq 0 ]; then
            echo -e '\e[00;32m'"\033[5m $ST \e[00m"
        else
            echo -e '\e[00;31m' "\033[5m NOT $ST \e[00m"
        fi
    elif [ "$CASE" == "stop" ]; then
        ST="STOPPED"
        sleep 5
        ps aux |grep "$PRESTA_GREPPROCESS" >/dev/null
		if [ $? -eq 0 ]; then   
			echo -e '\e[00;31m' "\033[5m NOT $ST \e[00m"
			echo " "
			T1=$(ps aux |grep "$PRESTA_GREPPROCESS")
			echo -e "Running $PRESTA_COUNTPROCESS instances are as follow:-"
			echo " "
			echo "$T1"
        else
            echo -e '\e[00;32m'"\033[5m $ST \e[00m"
        fi
	else
		echo " "
    fi
}


case "${1}" in
    start)
        clear 
        echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
		echo -e " "
		echo -n "Starting ${CONNECTOR_NAME}: "
        checkdaemon
        preproc
        logcheck

        start-stop-daemon --start --quiet --pidfile ${PRESTA_PIDFILE} \
        --chuid ${USER} --background --make-pidfile \
        --chdir ${CHDIR} --exec ${PRESTA_DAEMON} -- ${DAEMON_START}
        
		checkpid
        postproc
        echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
        echo -e "\n"
        ;;

    stop)
        clear
        echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
        echo -e " "
        echo -n "Stopping ${CONNECTOR_NAME}: "
        checkdaemon

        start-stop-daemon --stop --quiet --pidfile ${PRESTA_PIDFILE} \
        --oknodo

        postproc
        echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
        echo -e "\n"
        ;;

    restart)
        clear
        echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
        echo -e " "
        echo -n "Restarting ${CONNECTOR_NAME}: "
        checkdaemon
        logcheck
        checkpid
        restrt
        postproc
        echo -e "$(yes '-' | head -70 | paste -s -d '' -)"
        echo -e "\n"
        ;;
    
    *)
        N=/etc/init.d/${CONNECTOR_NAME}
        echo -e " "
        echo "Usage: ${CONNECTOR_NAME} {start | start <Log-level> | stop | restart | restart <Log-level>}" >&2
        echo "Log-level: info, debug_rpc, warn, test, critical, debug_sql, error, debug, debug_rpc_answer, notset" >&2
        echo -e "\n"
        exit 1
		;;

esac
exit 0