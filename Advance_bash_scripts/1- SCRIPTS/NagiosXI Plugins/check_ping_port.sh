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
LASTMODIFY="2020-05-27"
PROGNAME=`basename $0`

# Location to paping binary
PING="/usr/sbin/paping"

ST_OK=0
ST_WR=1
ST_CR=2
ST_UK=3

print_help() {
  echo "This script sends 3 TCP SYN pings to a host and compares critical and"
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
  echo "  -t/--timeout"
  echo "     timeout in milliseconds"
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


if [ ! -n "${HOST}" ]; then
  echo "ERROR : Missing host parameter"
  exit $ST_UK
elif [ ! -n "${PORT}" ]; then
  echo "ERROR : Missing port parameter"
  exit $ST_UK
elif [ ! -n "${TIMEOUT}" ]; then
  echo "ERROR : Missing timeout parameter"
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

RESULT=`${PING} $HOST -p $PORT -c 3 --nocolor -t $TIMEOUT 2>&1`
PARSE_RESULT=$(echo "$RESULT" | awk '{if(NR>8)print}')

PKT=$(echo $PARSE_RESULT | grep -o "Failed.*" | awk -F"[()]" '{print $2}' | cut -d% -f1)
MIN=$(echo $PARSE_RESULT | grep -o "Minimum.*" | awk '{print $3}' | cut -d, -f1)
AVG=$(echo $PARSE_RESULT | grep -o "Average.*" | awk '{print $3}' | cut -d, -f1)
MAX=$(echo $PARSE_RESULT | grep -o "Maximum.*" | awk '{print $3}' | cut -d, -f1)

if [ ! "$PKT" =~ "^[0-9]+([.][0-9]+)?$" ] || [ -z "$MIN" ] || [ -z "$MIN" ] || [ -z "$AVG" ]; then
  PERFDATA="'Packet Loss (%)'=${PKT}%;;;;; 'Round-Trip Minimum Time (ms)'=${MIN};;;;; 'Round-Trip Average Time (ms)'=${AVG};;;;; 'Round-Trip Maximum Time (ms)'=${MAX};;;;;" 
  if [ "$PKT" -eq "100.00" ]; then
    echo "CRITICAL: ${HOST} rta ${AVG}ms lost ${PKT}% | $PERFDATA"
    exit $ST_CR
  elif [ "${AVG%%ms*}" -ge "$CRITICAL" ]; then
    echo "CRITICAL: ${HOST} Round-Trip Time. Min ${MIN} Max ${MAX} Avg ${AVG}. | $PERFDATA"
    exit $ST_CR
  elif [ "${AVG%%ms*}" -lt "$CRITICAL" ] && [ "${AVG%%ms*}" -ge "$WARNING" ]; then
    echo "WARNING: ${HOST} Round-Trip Time. Min ${MIN} Max ${MAX} Avg ${AVG} | $PERFDATA"
    exit $ST_WR
  else
    echo "OK: ${HOST} rta ${AVG} lost ${PKT}% | $PERFDATA"
    exit $ST_OK
  fi
else
  echo "UNKNOWN: The plugin doesn't return enough values"
  exit $ST_UK
fi
