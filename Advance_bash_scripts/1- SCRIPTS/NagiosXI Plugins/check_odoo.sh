#!/bin/bash
#LAST_UPGRADED="2020-05-14"
#AUTHOR="John, Sodexis"

PROGNAME=`basename $0`


ST_OK=0
ST_WR=1
ST_CR=2
ST_UK=3

print_help() {
  print_version $PROGNAME $VERSION
  echo ""
  echo "$PROGNAME is a Nagios plugin to check a odoo process via ps."
  echo "You may provide odoo config file as process name to filter specific"
  echo "process. Please note that the output could be distorted if the"
  echo "argument matches various processes, so please make sure to use"
  echo "unique strings to match a process."
  echo ""
  echo ""
  echo "Options:"
  echo "  -f/--conffile)"
  echo "     Provide the the full path to odoo configuration name."
  echo "  -u/--user)"
  echo "     An user under whom the odoo process is running. used to filter the process."
  echo "  -w/--warning)"
  echo "     Defines a warning level in percentage. This warning level will be consider as"
  echo "     warning for limit_memory_soft"
  echo "  -c/--critical)"
  echo "     Defines a critical level in percentage. This critical level will be consider as"
  echo "     critical for limit_memory_hard" 
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
    -help|-h)
      print_help
      exit $ST_UK
      ;;
    --version|-v)
      print_version $PROGNAME $VERSION
      exit $ST_UK
      ;;
    --process|-f)
      CONFIG=$2
      shift
      ;;
    --user|-u)
      USR=$2
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

wc_vals() {
  for var in CONFIG USR WARNING CRITICAL ; do
    if [ ! -n "${!var}" ] ; then
      if [ "$var" == "CONFIG" ]; then
        echo "ERROR : Please provide the full path to Odoo configuration file -f (Config File)"
        exit $ST_UK
      elif [ "$var" == "USR" ]; then
        echo "ERROR : Please provide options for -u (user)"
        exit $ST_UK
      elif [ "$var" == "WARNING" ]; then
        echo "ERROR : Please provide options for -w (warning)"
        exit $ST_UK
      else
        echo "ERROR : Please provide options for -c (critical)"
        exit $ST_UK
      fi
    fi
  done
}

get_vals() {
  PROC_COUNT="$(pgrep -u $USR -f $CONFIG | wc -l)"
  GET_HTTP_WORKER=$(grep 'workers' $CONFIG | awk '{print $3}')
  GET_CRON_WORKER=$(grep 'max_cron_threads' $CONFIG | awk '{print $3}')
  GET_GEVENT_WORKER=1
  GET_TOTAL=$((GET_HTTP_WORKER+GET_CRON_WORKER+GET_GEVENT_WORKER+1))    #+1 is due to pgrep count parent pid along with child. 

  if [[ "$PROC_COUNT" -eq "0" ]]; then
    echo "CRITICAL: Odoo workers are not running"
    exit $ST_CR
  elif [[ "$PROC_COUNT" -lt "$GET_TOTAL" ]]; then
    echo "WARNING: Only ${PROC_COUNT}/${GET_TOTAL} Odoo workers are running"
    exit $ST_WR
  fi

  # We get no. of cores from nproc and add 00 to get maximum cpu percent.
  AVAIL_TOT_CPU=$(nproc)00
  ALERT_TOT_CPU_LEVEL=$((AVAIL_TOT_CPU - 100))     #If 3/4 of available CPU are used. 
  AVAIL_TOT_MEM="$(free -m | grep 'Mem:' | awk '{print $2}')"

  AVAIL_MX_MEM_WKR_S=`echo "$(grep '^limit_memory_soft' "${CONFIG}" | awk '{print $3}') / 1000 / 1000" | bc`
  AVAIL_MX_MEM_WKR_H=`echo "$(grep '^limit_memory_hard' "${CONFIG}" | awk '{print $3}') / 1000 / 1000" | bc`
  SET_WARNING=`echo "(${AVAIL_MX_MEM_WKR_S} * ${WARNING}) / 100" | bc`
  SET_CRITICAL=`echo "(${AVAIL_MX_MEM_WKR_H} * ${CRITICAL}) / 100" | bc`

  USED_CPU="$(top -b -p $(pgrep -d',' -f ${CONFIG}) -n 1 | awk 'NR>7 { sum += $9; } END { print sum; }')"
  CAL_MEM="$(top -b -p $(pgrep -d',' -f ${CONFIG}) -n 1 | awk 'NR>7 { sum += $10; } END { print sum; }')"
  USED_MEM=`echo "(${CAL_MEM} * ${AVAIL_TOT_MEM}) / 100" | bc`

  #calculate per worker.
  a=(`top -b -p $(pgrep -d',' -f ${CONFIG}) -n 1 | awk 'NR>7 {print $10}'`)
  OLDIFS="$IFS"
  IFS=$'\n'
  MX_WKR_MEM=`echo "${a[*]}" | sort -nr | head -n1`
  MX_WKR_MEM_MB=`echo "(${MX_WKR_MEM} * ${AVAIL_TOT_MEM}) / 100" | bc`
  IFS="$OLDIFS"
}

do_output() {
  output="Process: ${PROC_COUNT}, Total_Workers_CPU: ${USED_CPU}/${AVAIL_TOT_CPU} %, Total_Workers_MEM: ${USED_MEM}/${AVAIL_TOT_MEM} MB, Max_Worker_MEM: ${MX_WKR_MEM_MB} MB/ L-M-S ${AVAIL_MX_MEM_WKR_S} MB/ L-M-H ${AVAIL_MX_MEM_WKR_H} MB"  
}

do_perfdata() {
  perfdata="'Process'=${PROC_COUNT} 'Total_Workers_CPU_Used'=${USED_CPU}%;;;0;${AVAIL_TOT_CPU}; 'Total_Workers_MEM_Used'=${USED_MEM}MB;;;0;${AVAIL_TOT_MEM}; 'Max_Worker_MEM'=${MX_WKR_MEM_MB}MB;${SET_WARNING};${SET_CRITICAL};0;${AVAIL_MX_MEM_WKR_H};"
}

wc_vals
get_vals
do_output
do_perfdata

if [ -n "${SET_WARNING}" -a -n "${SET_CRITICAL}" ]; then
  if [ "${USED_CPU}" -ge "${ALERT_TOT_CPU_LEVEL}" ]; then
    output="Total_Workers_CPU: ${USED_CPU}/${AVAIL_TOT_CPU} %"
    echo "CRITICAL: ${output} | ${perfdata}"
    exit $ST_CR
  elif [ "${MX_WKR_MEM_MB}" -ge "${SET_CRITICAL}" ]; then
    output="Max_Worker_MEM: ${MX_WKR_MEM_MB }MB/ L-M-S ${AVAIL_MX_MEM_WKR_S} MB/ L-M-S ${AVAIL_MX_MEM_WKR_H} MB"
    echo "CRITICAL: ${output} | ${perfdata}"
    exit $ST_CR
  elif [ "${MX_WKR_MEM_MB}" -ge "${SET_WARNING}" -a "${MX_WKR_MEM_MB}" -lt "${SET_CRITICAL}" ]; then
    output="Max_Worker_MEM: ${MX_WKR_MEM_MB} MB/ L-M-S ${AVAIL_MX_MEM_WKR_S} MB/ L-M-S ${AVAIL_MX_MEM_WKR_H} MB"
    echo "WARNING: ${output} | ${perfdata}"
    exit $ST_WR
  else
    echo "OK: ${output} | ${perfdata}"
    exit $ST_OK
  fi
else
  echo "UNKNOWN - ${output} | ${perfdata}"
  exit $ST_UK
fi