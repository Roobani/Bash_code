#!/bin/bash

# Author: John, Sodexis.
# Description: This plugin check if any cron_name in scheduled action who's next_call is behind an hour with respect to the current check time.
# Do the test case, by removing 'AND active=true' in query.
# note: check postgresql time using: SELECT now(); Postgresql generally uses server timezone.  Odoo uses UTC which is stored in nextcall.  

# This is direct check using psql. should be installed in monitorning server.


ST_OK=0
ST_WR=1
ST_CR=2
ST_UK=3

print_help() {
  echo ""
  echo "Options:"
  echo "  -d/--database)"
  echo "     Provide the production database name."
  echo "  -t/--time)"
  echo "     Provide the time behind in hours."
  exit $ST_UK
}


while test -n "$1"; do
  case "$1" in
    -h)
      DBS_HOST=$2
      shift
      ;;
    -p)
      DBS_PORT=$2
      shift
      ;;
    -u)
      DBS_USER=$2
      shift
      ;;
    -up)
      DBS_PASS=$2
      shift
      ;;
    -d)
      DBS_DB=$2
      shift
      ;;
    -t)
      T=$2
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

if [[ -z "$DBS_HOST" ]] || [[ -z "$DBS_PORT" ]] || [[ -z "$DBS_USER" ]] || [[ -z "$DBS_PASS" ]] || [[ -z "$DBS_DB" ]] || [[ -z "$T" ]] ; then
  echo "UNKNOWN: This script requires values for -d/--database, -t/--time. Please check all arguments are provided"
  exit $ST_CR
fi


if [[ -z "$(PGPASSWORD=$DBS_PASS psql --set=sslmode=require -h ${DBS_HOST} -p ${DBS_PORT} -U ${DBS_USER} -d ${DBS_DB} -w -tAc "SELECT 1 FROM pg_database WHERE datname = '$DBS_DB'")" ]]; then
  echo "UNKNOWN: The database $DBS_DB not found. Check for any mistake in database name."
  exit $ST_CR
fi

SAVEIFS=$IFS
IFS=$'\n'
QUOTE="'"
DBNAME=(`PGPASSWORD=$DBS_PASS psql --set=sslmode=require -h ${DBS_HOST} -p ${DBS_PORT} -U ${DBS_USER} -d ${DBS_DB} -w --tuples-only -P format=unaligned -c "SELECT cron_name FROM ir_cron WHERE nextcall <= now() at time zone 'utc' - INTERVAL $QUOTE$T HOUR$QUOTE AND active=true"`);
IFS=$SAVEIFS

if [[ ${DBNAME[@]} ]]; then
  echo "CRITICAL: ${#DBNAME[@]} Cron Jobs nextcall is behind $T hour. $(printf "%s, " "${DBNAME[@]}" | cut -d "," -f 1-${#DBNAME[@]}) | 'Total Cron Jobs Errors'=${#DBNAME[@]};;;;;"
  exit $ST_CR
else
  echo "OK: Cron Jobs are good | 'Total Cron Jobs Errors'=${#DBNAME[@]};;;;;"
  exit $ST_OK
fi