#!/bin/sh

echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo ""
echo "Backing up $DIRS"
echo ""
# System Setup #
DIRS="/var/www/vhosts/sodexis.com /var/app/oracle/fast_recovery_area/"
BACKUP=/var/tmp/backup.$$
NOW=$(date +"%d-%m-%Y")
INCFILE="/root/tar-inc-backup.dat"
DAY=$(date +"%a")
FULLBACKUP="Sun"

# MySQL Setup #
MUSER="admin"
MPASS=""
MHOST="localhost"
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
GZIP="$(which gzip)"

# FTP server Setup #
FTPD="Sodexis_backup/Files_MySql-db/incremental"
FTPU="bak5655704"
FTPP="Dr1UeMS4"
FTPS="backup384.onlinehome-server.com"
NCFTP="$(which ncftpput)"

# Other stuff #
EMAILID="john@sodexis.com"
 
# Start Backup for file system #
[ ! -d $BACKUP ] && mkdir -p $BACKUP || :

# See if we want to make a full backup #
if [ "$DAY" == "$FULLBACKUP" ]; then
  rm $INCFILE
  FTPD="Sodexis_backup/Files_MySql-db/full"
  FILE="fs-full-$NOW.tar.gz"
  tar -pzcvf $BACKUP/$FILE $DIRS
else
  i=$(date +"%Hh%Mm%Ss")
  FILE="fs-i-$NOW-$i.tar.gz"
  tar -g $INCFILE -pzcvf $BACKUP/$FILE $DIRS
fi

# Start MySQL Backup #
# Get all databases name
 DBS="$($MYSQL -u $MUSER -h $MHOST -p$MPASS -Bse 'show databases')"
 for db in $DBS
 do
  FILE=$BACKUP/mysql-$db.$NOW-$(date +"%T").gz
  $MYSQLDUMP --single-transaction -u $MUSER -h $MHOST -p$MPASS $db | $GZIP -9 > $FILE
 done

REMOVAL_DATE=$(date -d “1 week ago” +”%d-%m-%Y”)

# Dump backup using FTP #
# Start FTP backup using ncftp
ncftp -u"$FTPU" -p"$FTPP" $FTPS<<EOF
rm -r $FTPD/$REMOVAL_DATE
mkdir -p $FTPD
mkdir -p $FTPD/$NOW
cd $FTPD/$NOW
lcd $BACKUP
mput *
quit
EOF

# Sends Mail if backup successful or failed #
if [ "$?" == "0" ]; then
 rm -rf $BACKUP
 T=/var/tmp/backup.good
 echo "Date: $(date)">$T
 echo "Hostname: $(hostname)" >>$T
 echo "" >>$T
 echo "Backup Successful" >>$T
 echo "" >>$T
 echo "Check the log file at /root/scripts/backup_output.log" >>$T
 mail  -s "$(hostname) - BACKUP SUCCESSFUL" "$EMAILID" <$T
 rm -f $T
else
 rm -rf $BACKUP
 T=/var/tmp/backup.fail
 echo "Date: $(date)">$T
 echo "Hostname: $(hostname)" >>$T
 echo "" >>$T
 echo "Backup failed" >>$T
 echo "" >>$T
 echo "Check the log file at /root/scripts/backup_output.log" >>$T
 mail  -s "$(hostname) - BACKUP FAILED" "$EMAILID" <$T
fi
