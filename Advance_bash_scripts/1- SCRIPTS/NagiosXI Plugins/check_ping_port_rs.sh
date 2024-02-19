#!/bin/ksh
#
# copyright sodexis GPL3
#
# This script sends 3 TCP SYN pings to a host and compares critical and
# warning tresholds against average round trip time (ms). It also reports
# critical on 100% packet loss. The user (e.g. "nagios") must have sudoers
# permission to run  paping. The port may be any used by a TCP service on
# the host.
#
# IMP NOTE: Make sure you have in visudo (NagiosXI server) as NAGIOSXI ALL = NOPASSWD:/usr/local/nagios/libexec/check_paping
# yum install ksh
# download paping linux binary from https://code.google.com/archive/p/paping/  and link to /usr/sbin 
###########################################################################

AUTHOR="John, Sodexis"
VERSION="check_paping 1.0"

# Location to paping binary
PING="/usr/sbin/paping"

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
	echo "This script sends 5 TCP SYN pings to a host and compares critical and"
	echo "warning tresholds against average round trip time (ms). It also reports"
	echo "critical on 100% packet loss. The user (e.g. "nagios") must have sudoers"
	echo "permission to run hping3. The port may be any used by a TCP service on"
	echo "the host."
    echo ""
    echo "$PROGNAME -h <HOST> -e 80 -i 4011 -t 10000 -w 3000.00,3000.00 -c 5000.00,5000.00"
    echo ""
    echo "Options:"
    echo "  -h/--host)"
    echo "     Provide a host name"
    echo "  -e/--externalport)"
    echo "     Provide an external port"
	echo "  -i/--internalport)"
    echo "     Provide an internal port"
    echo "  -w/--warning)"
    echo "     Router,Server average response time (RTA) Warning"
    echo "  -c/--critical)"
    echo "     Router,Server average response time (RTA) Critical"
	echo "	-t/--timeout"
	echo "	   timeout in milliseconds"
    exit $ST_UK
}

# Make sure the correct number of command line
# arguments have been supplied

if [ $# -lt 1 ]; then
    print_help
    exit $ST_UK
fi

while test -n "$1"; do
    case "$1" in
        --version|-v)
            print_version $PROGNAME $VERSION
            exit $ST_UK
            ;;
        --host|-h)
            HOST=$2
            shift
            ;;
        --extport|-e)
            EXTPORT=$2
            shift
            ;;
		--intport|-i)
            INTPORT=$2
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
		--timeout|-t)
            TIMEOUT=$2
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

argchk() {
	set -A TAB_WARNING `echo $WARNING | sed 's/,/ /g'` 
	set -A TAB_CRITICAL `echo $CRITICAL | sed 's/,/ /g'` 
	if [ "${#TAB_WARNING[@]}" -ne "2" ]; then
		echo "ERROR : Missing 2 parameter in Warning Threshold (comma seperated). Values should be as  -w ROUTER RTA, SERVER RTA"
		exit $ST_UK
    elif [ ${TAB_WARNING[0]} -ge ${TAB_CRITICAL[0]} -o ${TAB_WARNING[1]} -ge ${TAB_CRITICAL[1]} ]; then
        echo "ERROR : All Warning Threshold must be lower than Critical Threshold e.g -w 3000.00,3000.00 -c 5000.00,5000.00"
        exit $ST_UK
	else  
		ROUTER_WARNING_THRESHOLD=`echo ${TAB_WARNING[0]}`
		SERVER_WARNING_THRESHOLD=`echo ${TAB_WARNING[1]}`
	fi
	if [ "${#TAB_CRITICAL[@]}" -ne "2" ]; then
		echo "ERROR : Missing 2 parameter in Critical Threshold (comma seperated). Values should be as  -w ROUTER RTA, SERVER RTA"
		exit $ST_UK
	else 
		ROUTER_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL[0]}`
		SERVER_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL[1]}`
	fi
}


EXTPRE=`${PING} $HOST -p $EXTPORT -c 3 --nocolor -t $TIMEOUT 2>&1`
EXTPKT=`echo $EXTPRE | cut -d ',' -f 3 | awk -F"[()]" '{print $2}' | awk -F% '{print $1}'`
EXTAVG=`echo $EXTPRE | cut -d ',' -f 5 | awk '{print $3}' | awk -Fms '{print $1}'`

INTPRE=`${PING} $HOST -p $INTPORT -c 3 --nocolor -t $TIMEOUT 2>&1`
INTPKT=`echo $INTPRE | cut -d ',' -f 3 | awk -F"[()]" '{print $2}' | awk -F% '{print $1}'`
INTAVG=`echo $INTPRE | cut -d ',' -f 5 | awk '{print $3}' | awk -Fms '{print $1}'`

do_perf () {
	PERFOUT="'ROUTER Packet loss'=${EXTPKT};;;0;100.00; 'ROUTER RTA'=${EXTAVG}ms;${ROUTER_WARNING_THRESHOLD};${ROUTER_CRITICAL_THRESHOLD};;; 'SERVER Packet Loss'=${INTPKT};;;0;100.00; 'SERVER RTA'=${INTAVG}ms;${SERVER_WARNING_THRESHOLD};${SERVER_CRITICAL_THRESHOLD};;;" 
}

argchk
do_perf

if [ -n "$EXTAVG" -o -n "$INTAVG" ]; then
	if [ "$EXTPKT" -eq "100.00" ]; then
		echo "CRITICAL: Internet is DOWN. Router_Packet_Loss=${EXTPKT}% Router_RTA=${EXTAVG}ms | $PERFOUT"
		exit $ST_CR
	elif [ "$INTPKT" -eq "100.00" ]; then
		echo "CRITICAL: Server is DOWN. Server_Packet_Loss=${INTPKT}% Server_RTA=${INTAVG}ms | $PERFOUT"
		exit $ST_CR
	elif [ "$EXTAVG" -ge "$ROUTER_CRITICAL_THRESHOLD" ]; then
		echo "CRITICAL: Internet is SLOW. Router_Packet_Loss=${EXTPKT}% Router_RTA=${EXTAVG}ms | $PERFOUT"
		exit $ST_CR
    elif [ "$INTAVG" -ge "$SERVER_CRITICAL_THRESHOLD" ]; then
        echo "CRITICAL: Server LAN is SLOW. Server_Packet_Loss=${INTPKT}% Server_RTA=${INTAVG}ms | $PERFOUT"
        exit $ST_CR
	elif [ "$EXTAVG" -lt "$ROUTER_CRITICAL_THRESHOLD" -a "$EXTAVG" -ge "$ROUTER_WARNING_THRESHOLD" ]; then
		echo "WARNING: Internet is SLOW. Router_Packet_Loss=${EXTPKT}% Router_RTA=${EXTAVG}ms | $PERFOUT"
		exit $ST_WR
    elif [ "$INTAVG" -lt "$SERVER_CRITICAL_THRESHOLD" -a "$INTAVG" -ge "$SERVER_WARNING_THRESHOLD" ]; then
        echo "WARNING: Server LAN is SLOW. Server_Packet_Loss=${INTPKT}% Server_RTA=${INTAVG}ms | $PERFOUT"
        exit $ST_WR
    else
		echo "OK: Router_Packet_Loss=${EXTPKT}% Router_RTA=${EXTAVG}ms, Server_Packet_Loss=${INTPKT}% Server_RTA=${INTAVG}ms | $PERFOUT"
		exit $ST_OK
	fi
else
	echo "UNKNOWN: The plugin didn't return any valid output."
	exit $ST_UK
fi