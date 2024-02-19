#!/bin/ksh
#
# copyright Whit Blauvelt 18 Sept. 2012 - GPL3
#
# This script sends 5 TCP SYN pings to a host and compares critical and
# warning tresholds against average round trip time (ms). It also reports
# critical on 100% packet loss. The user (e.g. "nagios") must have sudoers
# permission to run hping3. The port may be any used by a TCP service on
# the host.
#
# IMP NOTE: Make sure you have in visudo (NagiosXI server) as NAGIOSXI ALL = NOPASSWD:/usr/local/nagios/libexec/check_hping
# yum install ksh
###########################################################################

AUTHOR="John, Sodexis"
VERSION="check_hping v0.03"

# edit to match location on system; hping2 should also work
HPING="/usr/sbin/hping3"

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
    echo "$PROGNAME -h <HOST> -p <PORT> -w <WARNING> -c <CRITICAL>"
    echo ""
    echo "Options:"
    echo "  -h/--host)"
    echo "     Provide a host name"
    echo "  -p/--port)"
    echo "     Provide an external port"
	echo "  -w/--warning)"
    echo "     Average response time (RTA) Warning"
    echo "  -c/--critical)"
    echo "     Average response time (RTA) Critical"
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
            shift
            ;;
        --host|-h)
            HOST=$2
            shift
            ;;
        --port|-p)
            PORT=$2
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

argchk() {
	if [ ! -n "${HOST}" ]; then
		echo "ERROR : Missing host parameter"
		exit $ST_UK
    elif [ ! -n "${PORT}" ]; then
        echo "ERROR : Missing port parameter"
        exit $ST_UK
    elif [ ! -n "${WARNING}" ]; then
        echo "ERROR : Missing rta waring parameter"
        exit $ST_UK
    elif [ ! -n "${CRITICAL}" ]; then
        echo "ERROR : Missing rta critical parameter"
        exit $ST_UK
    elif [ "$WARNING" -ge "$CRITICAL" ]; then
        echo "ERROR : Warning threshold must be lower than Critical threshold"
        exit $ST_UK
    fi 
 }

do_perf () {
    PERFOUT="'Packet Loss'=${PKT}%;;;0;100; 'RTA'=${AVG}ms;${WARNING};${CRITICAL};;;" 
}

PRE=`${HPING} -q -n -p $PORT -c 1 -S $HOST 2>&1`
PKT=`echo $PRE | cut -d ',' -f 3 | awk '{ print $1 }' | rev | cut -c 2- | rev`
AVG=`echo $PRE | cut -d '/' -f 4`

argchk
do_perf

if [ -n "$AVG" ]; then
	if [ "$PKT" -eq "100" ]; then
		echo "CRITICAL: Server is DOWN. Packet_Loss=${PKT} RTA=${AVG} | $PERFOUT"
		exit $ST_CR
	elif [ "$INTAVG" -ge "$CRITICAL" ]; then
        echo "CRITICAL: Server is SLOW. Packet_Loss=${PKT} RTA=${AVG} | $PERFOUT"
        exit $ST_CR
	elif [ "$INTAVG" -lt "$CRITICAL" -a "$INTAVG" -ge "$WARNING" ]; then
        echo "WARNING: Server is SLOW. Packet_Loss=${PKT} RTA=${AVG} ms | $PERFOUT"
        exit $ST_WR
    else
        echo "OK: Packet_Loss=${PKT} RTA=${AVG} ms | $PERFOUT"
        exit $ST_OK
    fi
else
	echo "UNKNOWN: The plugin didn't return any valid output."
	exit $ST_UK
fi

