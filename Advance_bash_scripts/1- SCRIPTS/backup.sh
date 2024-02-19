#!/bin/sh

echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo ""
echo "Backing up $DIRS"
echo ""

# System Setup #
DIRS="/var/www"
BACKUP=/tmp/backup.$$
NOW=$(date +"%d-%m-%Y")
INCFILE="/root/tar-inc-backup.dat"
DAY=$(date +"%a")
FULLBACKUP="Sun"

# MySQL Setup #
MUSER="admin"
MPASS="59LuwT36"
MHOST="localhost"
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
GZIP="$(which gzip)"

# FTP server Setup #
FTPD="/home/admin/incremental"
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
  FTPD="/home/admin/full"
  FILE="fs-full-$NOW.tar.gz"
  tar -zcvf $BACKUP/$FILE $DIRS
else
  i=$(date +"%Hh%Mm%Ss")
  FILE="fs-i-$NOW-$i.tar.gz"
  tar -g $INCFILE -zcvf $BACKUP/$FILE $DIRS
fi

# Start MySQL Backup #
# Get all databases name
# DBS="$($MYSQL -u $MUSER -h $MHOST -p$MPASS -Bse 'show databases')"
# for db in $DBS
# do
 # FILE=$BACKUP/mysql-$db.$NOW-$(date +"%T").gz
 # $MYSQLDUMP --single-transaction -u $MUSER -h $MHOST -p$MPASS $db | $GZIP -9 > $FILE
# done

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

# Find out if ftp backup failed or not #
if [ "$?" == "0" ]; then
 rm -f $BACKUP
 T=/tmp/backup.good
  
 echo "Backup Successful" >>$T
 mail  -s "$(hostname) - BACKUP SUCCESSFUL" "$EMAILID" <$T
else
 rm -rf $BACKUP
 T=/tmp/backup.fail
 echo "Date: $(date)">$T
 echo "Hostname: $(hostname)" >>$T
 echo "Backup failed" >>$T
 mail  -s "BACKUP FAILED" "$EMAILID" <$T
 rm -f $T
fi
