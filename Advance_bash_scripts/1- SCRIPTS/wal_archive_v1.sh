#!/bin/bash -xv
PG_XLOG="$1"
PG_XLOG_FILENAME="$2"
HOST="odoo.mattmccoy.com"
ARCHIVE_DIR="/pg_archive/matthews"
EMAIL="dailymonitoring@sodexis.com john@sodexis.com"
ERROR_COUNT_FILE="/tmp/replication_archive_error_count.txt"

#--------------------------------------------------------
OLD_COUNT=$(cat ${ERROR_COUNT_FILE})

D=$(date)

/usr/bin/rsync -W -az "${PG_XLOG:?}" postgres@standby:"${ARCHIVE_DIR:?}"/"${PG_XLOG_FILENAME:?}"
if [ "$?" -ne "0" ]; then
  rm -rf "${ARCHIVE_DIR:?}"/"${PG_XLOG_FILENAME:?}"
  NEW_COUNT="$((OLD_COUNT + 1))"
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
