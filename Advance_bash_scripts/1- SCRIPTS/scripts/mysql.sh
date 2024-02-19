#!/bin/bash

NOW=$(date +"%d-%m-%Y")
MUSER="admin"
MHOST="localhost"
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
GZIP="$(which gzip)"
BACKUP=/Backup/MySQL_Backup

# Start Backup for file system #
[ ! -d $BACKUP ] && mkdir -p $BACKUP || :

# Start MySQL Backup #
# Get all databases name
 DBS="$($MYSQL -u$MUSER -p`cat /etc/psa/.psa.shadow` -Bse 'show databases')"
#echo $DBS
 for db in $DBS
 do
  FILE=$BACKUP/mysql-$db.$NOW.gz
  $MYSQLDUMP --single-transaction -u$MUSER -p`cat /etc/psa/.psa.shadow` $db | $GZIP -9 > $FILE
done
exit 0
