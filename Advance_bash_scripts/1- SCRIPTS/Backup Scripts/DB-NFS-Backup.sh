#!/bin/bash
# Maintainer: Sodexis Inc (admin@sodexis.com)
# Description: This script store DB backup to OVH FTP. 
# prerequisites: apt-get install postfix mutt heirloom-mailx lrzip tree rsync

CONFIGPATH="/etc/odoo-server-11.conf"
HOST="odoo.extractiontek.com"
DBNAME="ETS_Master"
NFS_MOUNT_BASE="/mnt/nfs-backup/extractiontek"
BACKUPDIR="${NFS_MOUNT_BASE}/Database"
LOGDIR="/opt/support_files/scripts/logs"
# Email Address to send mail to? (user@domain.com)
MAILADDR="john@sodexis.com"
REPLYTO="john@sodexis.com"
BCC="dailymonitoring@sodexis.com"
# Options to Vacuum before running the backup
# 0 : Do not perform any Vacuum functions
# 1 : Vacuum only (Default)
# 2 : Vacuum and Analyze
# 3 : Do a Full Vacuum and Analyze *Note* This can take a long time.
VACUUM=2
# No of days to keep backup copies.
BACKUP_COPIES=5
# Use compression (yes/no), if this set to "no" , then COMPRESS_TYPE has no effect.
NEED_COMPRESS=yes
# Choose Compression type. (gzip or bzip2)
COMPRESS_TYPE=bzip2

#====================== Do not edit below this line ======================================#



SCRIPT_NAME=`basename $0`

LOGFILE=${LOGDIR}/${SCRIPT_NAME}-`date +%m_%d-%H:%M:%S`.log
LOGERR=${LOGDIR}/${SCRIPT_NAME}-ERRORS-`date +%m_%d-%H:%M:%S`.log
WARNING=$LOGDIR/$SCRIPT_NAME-WARNING-`date +%m_%d-%H:%M:%S`.log
VACUUMDB_LOG=$LOGDIR/$SCRIPT_NAME-VACUUMDB-$(date +%F_%T).log   # vacuumdb log

#
CONNECT_DB_IP=$(grep 'db_host' $CONFIGPATH | awk '{ print $3 }')
CONNECT_DB_PORT=$(grep 'db_port' $CONFIGPATH | awk '{ print $3 }')
CONNECT_DB_NAME=$(grep 'db_template' $CONFIGPATH | awk '{ print $3 }')
CONNECT_DB_USER=$(grep 'db_user' $CONFIGPATH | awk '{ print $3 }')
CONNECT_DB_PASS=$(grep 'db_password' $CONFIGPATH | awk '{ print $3 }')
#
DATE=`date +%Y-%m-%d_%Hh%Mm`                             # Datestamp e.g 2002-09-21
DOW=`date +%A`                                           # Day of the week e.g. Monday
DNOW=`date +%u`                                          # Day number of the week 1 to 7 where 1 represents Monday
DOM=`date +%d`                                           # Date of the Month e.g. 27
M=`date +%B`                                             # Month e.g January
MN=`date +%m`						                     # Month Number e.g 01...12
W=`date +%V`                                             # Week Number e.g 37

# IO redirection for logging.
touch $LOGFILE
exec 6>&1
exec > $LOGFILE
touch $LOGERR
exec 7>&2
exec 2> $LOGERR

if [ "$VACUUM" = "2" ]; then VACUUM_OPT="--analyze"; elif [ "$VACUUM" = "3" ]; then VACUUM_OPT="--analyze --full"; fi

OPT="--format=c --no-owner"

#Check if backupdir is mounted.
if ! mountpoint -q "$NFS_MOUNT_BASE"; then
    echo ERROR: "$NFS_MOUNT_BASE" was not mounted. | mail -s "ERRORS - Odoo Database Backup for $HOST" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
    exit 1
fi

if [ ! -d "${BACKUPDIR}/${DBNAME}" ]; then
    mkdir -p "${BACKUPDIR}/${DBNAME}"
fi

# Database dump function
dbdump () {
    if [ "$VACUUM" != "0" ]; then
    	date1=$(date +"%s")
    	if [ "$VACUUM" -eq "2" ]; then 
            echo -n "VACUUMDB (ANALYZE): "
        elif [ "$VACUUM" -eq "3" ]; then
            echo -n "VACUUMDB (FULL, ANALYZE): "
        else
            echo -n "VACUUMDB: "
        fi
    	PGPASSWORD=$CONNECT_DB_PASS vacuumdb --username=${CONNECT_DB_USER} --host=${CONNECT_DB_IP} --port=${CONNECT_DB_PORT} -e -w $VACUUM_OPT $1 > $VACUUMDB_LOG 2>&1
        echo -e "DONE"
	    date2=$(date +"%s")
	    diff=$(($date2-$date1))
        echo -e "Time taken for vacuumdb: $(($diff / 60)) minutes and $(($diff % 60)) seconds"
        echo
    fi
    PGPASSWORD=$CONNECT_DB_PASS pg_dump -U ${CONNECT_DB_USER} -h ${CONNECT_DB_IP} -p ${CONNECT_DB_PORT} -w $OPT $1 > $2
}

compression () {
    if [ "$COMPRESS_TYPE" = "gzip" ]; then
        gzip -f "$1"
        echo Compression Information of "${1}.gz"
        gzip -l "$1.gz"
    elif [ "$COMPRESS_TYPE" = "bzip2" ]; then
        echo Compression information of "${1}.bz2"
        bzip2 -f -v $1 2>&1
    fi
}

echo -e $(yes '=' | head -70 | paste -s -d '' -)
echo
echo Backup of Database Server - $HOST
echo
echo -e $(yes '=' | head -70 | paste -s -d '' -)
echo Backup Start Time `date`
echo -e $(yes '=' | head -70 | paste -s -d '' -)
echo Daily Backup of Database \( $DBNAME \)
echo Rotating last $BACKUP_COPIES Backup...
REM="$(date +'%A' -d "$BACKUP_COPIES day ago")"
eval rm -fv "${BACKUPDIR}/${DBNAME}/*.${REM}.dump*"
echo
dbdump "${DBNAME}" "${BACKUPDIR}/${DBNAME}/${DBNAME}_${DATE}.${DOW}.dump"
compression "${BACKUPDIR}/${DBNAME}/${DBNAME}_${DATE}.${DOW}.dump" &
wait $!
echo -e $(yes '-' | head -125 | paste -s -d '' -)
echo " "
echo
echo Store Files are:-
echo
tree -h $BACKUPDIR
echo
# Sleep is needed for du to report size along with current backup. 
sleep 10
echo Total disk space used for backup storage..
echo Size - Location
echo `du -hs "$BACKUPDIR"`
echo
echo
echo -e "$(yes '=' | head -70 | paste -s -d '' -)"
echo Backup End `date`
echo -e "$(yes '=' | head -70 | paste -s -d '' -)"


#Clean up IO redirection
exec 1>&6 6>&-      # Restore stdout and close file descriptor #6.
exec 1>&7 7>&-      # Restore stdout and close file descriptor #7.
# -s means file is not zero size
if [ -s "$LOGERR" -a -s "$LOGFILE" ]; then
    cat "$LOGERR" | mail -s "ERRORS - Odoo Database Backup for $HOST" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
    cat "$LOGFILE" | mail -s "SUCCESS - Odoo Database Backup for $HOST" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
elif [ -s "$LOGERR" -a ! -s "$LOGFILE" ]; then
    cat "$LOGERR" | mail -s "ERRORS - Odoo Database Backup for $HOST" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
else
    cat "$LOGFILE" | mail -s "SUCCESS - Odoo Database Backup for $HOST" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
fi

if [ -s "$LOGERR" ]; then
    STATUS=1
else
    STATUS=0
fi
# Clean up Logfile
find "$LOGDIR"/"${SCRIPT_NAME}"-*.log -type f -mtime +3 -exec rm -f {} +
exit $STATUS