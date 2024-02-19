#!/bin/bash -xv
PG_XLOG="$1"
PG_XLOG_FILENAME="$2"
HOST="odoo.mattmccoy.com"
ARCHIVE_DIR="/pg_archive/matthews"
ARCHIVE_TO_KEEP="3"     #No of days of archive logs to keep
EMAIL="dailymonitoring@sodexis.com john@sodexis.com"
ERROR_COUNT_FILE="/tmp/replication_archive_error_count.txt"

#--------------------------------------------------------
OLD_COUNT=`cat ${ERROR_COUNT_FILE}`
DNOW=`date +%u`
hour=$(date +%H)
D=`date`

#Do the cleanup if the day is Monday or Thursday and time is between 11 p.m. UTC and 22 hrs UTC
if [ "$DNOW" -eq "1" -o "$DNOW" -eq "4" -a "$hour" -ge 11 -a "$hour" -lt 22 ]; then
  find "${ARCHIVE_DIR}"/ -type f -mtime +"${ARCHIVE_TO_KEEP}" -exec rm -f {} +
  if [ "$?" -eq "1" ]; then
    echo "The wal_archive script could not cleanup the archive directory of $HOST" | mail -s "ERROR - WAL Archive for $HOST" "$EMAIL"
  fi
fi

if [ ! -f "${ARCHIVE_DIR}"/"${PG_XLOG_FILENAME}" ]; then
  cp "${PG_XLOG}" "${ARCHIVE_DIR}"/"${PG_XLOG_FILENAME}"
  /usr/bin/rsync -W -az "${PG_XLOG}" postgres@192.168.25.9:"${ARCHIVE_DIR}"/"${PG_XLOG_FILENAME}"
  if [ "$?" -ne "0" ]; then
    rm -rf "${ARCHIVE_DIR}"/"${PG_XLOG_FILENAME}"
    NEW_COUNT=`expr $OLD_COUNT + 1`
    if [ "$NEW_COUNT" -ge "100" ]; then
        echo -e "${D}""\n""Rsync could not transfer the WAL file from Master to slave." | mail -s "ALERT - WAL Archive for $HOST" "$EMAIL"
        echo "0" > $ERROR_COUNT_FILE
    else
        echo "$NEW_COUNT" > $ERROR_COUNT_FILE
    fi
    exit 1
  else
    echo "0" > $ERROR_COUNT_FILE
    exit 0
  fi
fi
