#!/bin/bash

VIRTENV_PATH=/home/sodexis/virt_env/ETS_11.0
DAEMON=/opt/odoo-11/src/11.0/odoo-bin
NAME=odoo-server-11
CONFIGFILE="/etc/odoo-server-11.conf"
LOG=/var/log/odoo-11/odoo-server.log
USER=sodexis

#------------------ End of variables ---------------------------
PATH="${VIRTENV_PATH}"/bin:/bin:/sbin:/usr/bin
VIRTENV="${VIRTENV_PATH}"/bin/python
# pidfile
PIDFILE=/var/run/$NAME.pid
CHDIR="$(dirname "${DAEMON}")"/
# Additional options that are passed to the Daemon.
DAEMON_OPTS="-c $CONFIGFILE --logfile=${LOG}"

[ -x $DAEMON ] || exit 0
[ -f $CONFIGFILE ] || exit 0

checkpid() {
    [ -f $PIDFILE ] || return 1
    pid=`cat $PIDFILE`
    [ -d /proc/$pid ] && return 0
    return 1
}

case "${1}" in
        start)
                echo -n "Starting ${NAME}: "

                start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
                        --chuid ${USER} --background --make-pidfile \
                        --chdir ${CHDIR} --exec ${VIRTENV} ${DAEMON} -- ${DAEMON_OPTS}

                echo "${NAME}."
                ;;

        stop)
                echo -n "Stopping ${NAME}: "

                start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile ${PIDFILE} \
                        --oknodo

                echo "${NAME}."
                ;;

        restart|force-reload)
                echo -n "Restarting ${NAME}: "

                start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile ${PIDFILE} \
                        --oknodo
      
                sleep 5

                start-stop-daemon --start --quiet --pidfile ${PIDFILE} \
                        --chuid ${USER} --background --make-pidfile \
                        --chdir ${CHDIR} --exec ${VIRTENV} ${DAEMON} -- ${DAEMON_OPTS}

                echo "${NAME}."
                ;;

        *)
                N=/etc/init.d/${NAME}
                echo "Usage: ${NAME} {start|stop|restart|force-reload}" >&2
                exit 1
                ;;
esac

exit 0