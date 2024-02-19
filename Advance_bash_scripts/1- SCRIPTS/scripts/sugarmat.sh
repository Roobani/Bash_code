#!/bin/bash
NOW=$(date +"%d-%m-%Y")
BACKUP="/backup/sugarcrm"
# MySQL Setup #
MUSER="admin"
MPASS="59LuwT36"
MHOST="localhost"
MYSQLDUMP="/usr/bin/mysqldump"
GZIP="/bin/gzip"
DBS="sugarmatthews"
FILE=$BACKUP/Sugar-DB-$NOW.sql
$MYSQLDUMP --single-transaction -u $MUSER -h $MHOST -p$MPASS $DBS > $FILE
exit 0

