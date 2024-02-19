#!/bin/bash

NOW=$(date +"%d-%m-%Y")
DIR="/var/www/vhosts/sodexis.com/subdomains/test/httpsdocs/sugarcrm /var/www/vhosts/sodexis.com/subdomains/test/httpsdocs/tmp"
WEBDIR="/var/www/vhosts/sodexis.com/subdomains/databases/httpsdocs/data/matthews/SugarCRM"
BACKUP=/backup/sugarcrm
MUSER="admin"
MPASS="59LuwT36"
MHOST="localhost"
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
GZIP="$(which gzip)"
TAR="$(which tar)"

[ ! -d $BACKUP ] && mkdir -p $BACKUP || :
rm -rf $BACKUP/*
DBS='sugarmatthews'
FILE=$BACKUP/$DBS-$NOW.sql.gz
FILEDB=$BACKUP/SugarCRM-$NOW.tar.gz
$MYSQLDUMP -u $MUSER -h $MHOST -p$MPASS $DBS | $GZIP -9 > $FILE
$TAR -zcpvf $FILEDB $DIR

[ ! -d $WEBDIR ] && mkdir -p $WEBDIR || :
rm -rf $WEBDIR/*
cp -R $BACKUP/* $WEBDIR
exit 0
