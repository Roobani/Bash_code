#!/bin/bash

# Author: John, Sodexis.
# Description: This plugin check if any cron_name in scheduled action who's next_call is behind an hour with respect to the current check time.
# Do the test case, by removing 'AND active=true' in query.
# note: check postgresql time using: SELECT now(); Postgresql generally uses server timezone.  Odoo uses UTC which is stored in nextcall.  


ST_OK=0
ST_WR=1
ST_CR=2
ST_UK=3

print_help() {
  echo ""
  echo "Options:"
  echo "  -f/--conffile)"
  echo "     Provide the the full path to odoo configuration name."
  echo "  -d/--database)"
  echo "     Provide the production database name."
  echo "  -t/--time)"
  echo "     Provide the time behind in hours."
  exit $ST_UK
}


while test -n "$1"; do
  case "$1" in
    -help|-h)
      print_help
      exit $ST_UK
      ;;
    -f)
      CONFIG=$2
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

if [[ -z "$CONFIG" ]] || [[ -z "$DBS_DB" ]] || [[ -z "$T" ]]; then
  echo "UNKNOWN: This script requires values for -f/--conffile, -d/--database, -t/--time. Please check all arguments are provided"
  exit $ST_CR
fi

if [[ ! -f "$CONFIG" ]]; then
  echo "UNKNOWN: The Configuration file path $CONFIG is invalid. Check the path"
  exit $ST_CR
fi

DBS_HOST=$(grep 'db_host' $CONFIG | awk '{print $3}')
DBS_PORT=$(grep 'db_port' $CONFIG | awk '{print $3}')
DBS_USER=$(grep 'db_user' $CONFIG | awk '{print $3}')
DBS_PASS=$(grep 'db_password' $CONFIG | awk '{print $3}')
DBS_TEMPLATE=$(grep 'db_template' $CONFIG | awk '{print $3}')

if [[ -z "$(PGPASSWORD=$DBS_PASS psql -h ${DBS_HOST} -p ${DBS_PORT} -d ${DBS_TEMPLATE} -U ${DBS_USER} -w -tAc "SELECT 1 FROM pg_database WHERE datname = '$DBS_DB'")" ]]; then
  echo "UNKNOWN: The database $DBS_DB not found. Check for any mistake in database name."
  exit $ST_CR
fi

SAVEIFS=$IFS
IFS=$'\n'
QUOTE="'"
DBNAME=(`PGPASSWORD=$DBS_PASS psql -h $DBS_HOST -p $DBS_PORT -d $DBS_DB -U $DBS_USER -w --tuples-only -P format=unaligned -c "SELECT cron_name FROM ir_cron WHERE nextcall <= now() at time zone 'utc' - INTERVAL $QUOTE$T HOUR$QUOTE AND active=true"`);
IFS=$SAVEIFS

if [[ ${DBNAME[@]} ]]; then
  echo "CRITICAL: ${#DBNAME[@]} Cron Jobs nextcall is behind $T hour. $(printf "%s, " "${DBNAME[@]}" | cut -d "," -f 1-${#DBNAME[@]}) | 'Total Cron Jobs Errors'=${#DBNAME[@]};;;;;"
  exit $ST_CR
else
  echo "OK: Cron Jobs are good | 'Total Cron Jobs Errors'=${#DBNAME[@]};;;;;"
  exit $ST_OK
fi