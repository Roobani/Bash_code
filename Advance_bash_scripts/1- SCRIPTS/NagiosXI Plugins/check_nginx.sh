#!/bin/bash

#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

PROGNAME=`basename $0`
VERSION="Version 1.2,"
AUTHOR="2017, John, Sodexis)"

ST_OK=0
ST_WR=1
ST_CR=2
ST_UK=3

print_version() {
    echo "$VERSION $AUTHOR"
}

print_help() {
    print_version $PROGNAME $VERSION
    echo ""
    echo "$PROGNAME is a Nagios plugin executed via check_nrpe to check whether nginx is running."
    echo "It also parses the nginx's status page to get requests and"
    echo "connections per second as well as requests per connection. You"
    echo "may have to alter your nginx configuration so that the plugin"
    echo "can access the server's status page."
    echo "The plugin is highly configurable for this reason. See below for"
    echo "available options."
    echo ""
    echo "$check_nrpe -c check_nginx -a '-H localhost -p /var/run -n nginx.pid -s nginx_status -w [-w INT] [-c INT] "
	echo "e.g. /check_nginx -H localhost -p /var/run -n nginx.pid -s nginx_status -w 15000 -c 20000" 
    echo ""
    echo "Options:"
    echo "  -H/--hostname)"
    echo "     Defines the hostname. Default is: localhost"
    echo "  -p/--pid-location)"
    echo "     Path where nginx's pid file is being stored.eg: /var/run/nginx.pid"
    echo "  -s/--status-page)"
    echo "     Name of the server's status page defined in the location"
    echo "     directive of your nginx configuration. Default is:"
    echo "     nginx_status"
    echo "  -w/--warning)"
    echo "     Sets a warning level for requests per second. Default is: off"
    echo "  -c/--critical)"
    echo "     Sets a critical level for requests per second. Default is:"
	echo "     off"
    exit $ST_UK
}

while test -n "$1"; do
    case "$1" in
        -help|-h)
            print_help
            exit $ST_UK
            ;;
        --version|-v)
            print_version $PROGNAME $VERSION
            exit $ST_UK
            ;;
        --hostname|-H)
            HOST=$2
            shift
            ;;
        --pid-location|-p)
            PID_LOCATION=$2
            shift
            ;;
        --status-page|-s)
            STATUS_PAGE=$2
            shift
            ;;
        --warning|-w)
            WARNING=$2
            shift
            ;;
        --critical|-c)
            CRITICAL=$2
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            print_help
            exit $ST_UK
            ;;
        esac
    shift
done


if [ ! -n "${HOST}" ]; then
	echo "ERROR : Missing host parameter. -H"
	exit $ST_UK
elif [ ! -n "${PID_LOCATION}" ]; then
    echo "ERROR : Missing pid path parameter. -p"
    exit $ST_UK
elif [ ! -n "${STATUS_PAGE}" ]; then
    echo "ERROR : Missing nginx pid name. -s"
    exit $ST_UK
elif [ ! -n "${WARNING}" ]; then
    echo "ERROR : Missing warning parameter"
    exit $ST_UK
elif [ ! -n "${CRITICAL}" ]; then
    echo "ERROR : Missing rta critical parameter"
    exit $ST_UK
elif [ "$WARNING" -ge "$CRITICAL" ]; then
    echo "ERROR : Warning threshold must be lower than Critical threshold"
    exit $ST_UK
fi 


PID=`cat $PID_LOCATION`
if [ ! -f "$PID_LOCATION" -o ! -d "/proc/$PID" ]; then
	RT=2
else
    RT=0
fi

OUT1=`wget -O- -q -t 3 -T 3 http://${HOST}/${STATUS_PAGE}`
sleep 1
OUT2=`wget -O- -q -t 3 -T 3 http://${HOST}/${STATUS_PAGE}`

if [ -z "$OUT1" -o -z "$OUT2" ]; then
    RT=1
else
    TMP1_REQPSEC=`echo ${OUT1}|awk '{print $10}'`
    TMP2_REQPSEC=`echo ${OUT2}|awk '{print $10}'`
    REQPSEC=`expr $TMP2_REQPSEC - $TMP1_REQPSEC`

    TMP1_CONPSEC=`echo ${OUT1}|awk '{print $9}'`
    TMP2_CONPSEC=`echo ${OUT2}|awk '{print $9}'`
    CONPSEC=`expr $TMP2_CONPSEC - $TMP1_CONPSEC`

    REQPCON=`echo "scale=2; $REQPSEC / $CONPSEC" | bc -l`
    if [ "$REQPCON" = ".99" ]; then
        REQPCON="1.00"
    fi
fi

RESULT="$REQPSEC requests per second, $CONPSEC connections per second, $REQPCON requests per connection"
PERFDATA="'STATUS'=$RT;1;2;-3;3; 'REQUEST_PER_SEC'=$REQPSEC;$WARNING;$CRITICAL;;; 'CONNECTION_PER_SEC'=$CONPSEC;;;;; 'CONNECTION_PER_REQ'=$REQPCON;;;;;"

if [ "$RT" -eq "2" ]; then
	echo "CRITICAL: Nginx is not running | ${PERFDATA}"
	exit $ST_CR
else
	if [ "$RT" -eq "1" ]; then
		echo "WARNING: Nginx status page is empty | ${PERFDATA}"
		exit $ST_WR
	else
		if [ "$REQPSEC" -ge "$CRITICAL" ]; then
			echo "CRITICAL: Nginx - $REQPSEC requests per second | ${PERFDATA}"
			exit $ST_CR
		elif ["$REQPSEC" -ge "$WARNING" -a "$REQPSEC" -lt "$CRITICAL" ]; then
	        echo "WARNING: Nginx - $REQPSEC requests per second | ${PERFDATA}"
	    	exit $ST_WR
        else
            echo "OK: Nginx - ${RESULT} | ${PERFDATA}"
			exit $ST_OK
    	fi
    fi
fi
