#!/bin/bash
# Maintainer: Sodexis Inc (admin@sodexis.com)
# Description: This script store DB backup and Filestore to OVH FTP. 
# prerequisites: apt-get install postfix mutt s-nail lrzip tree rsync
# ln -s /usr/bin/s-nail /usr/bin/mail
# Extract dump: bzip2 -dk <dump>.bz2

CONFIGPATH="/opt/odoo/srtest11-odoo/conf/odoo.conf"
HOST="srtest11.sodexis.com"
DBNAME="SR_Master"
NFS_MOUNT_BASE="/mnt/nfs-backup/LS_PRO"
DB_BACKUPDIR="${NFS_MOUNT_BASE}/Database"
FS_BACKUPDIR="${NFS_MOUNT_BASE}/Filestore"
LOGDIR="/opt/support_files/scripts/logs"

MAILADDR="john@sodexis.com"
export REPLYTO="john@sodexis.com"
REPLYTO="john@sodexis.com"
#BCC="dailymonitoring@sodexis.com"

# Database specific
VACUUM=2              # 0: No vacuum, 1:vacuum only, 2: vacuum and analyze, 3: Full vacuum.
BACKUP_COPIES=5       # No of days to keep backup copies.
NEED_COMPRESS=yes     # Compression (yes/no)
COMPRESS_TYPE=bzip2   # Compression Type (gzip or bzip2)

# Filestore specific
RSYNC_OPT="-qrlptDuvhW --checksum --delete-after"



#====================== Do not edit below this line ======================================#

SCRIPT_NAME=`basename $0`
DATE=`date +%Y-%m-%d_%Hh%Mm`            # Datestamp e.g 2002-09-21
DOW=`date +%A` 
LOGFILE=${LOGDIR}/${SCRIPT_NAME}-$(date +%F_%T).log
LOGERR=$LOGDIR/$SCRIPT_NAME-ERRORS-$(date +%F_%T).log

CONNECT_DB_IP=$(grep 'db_host' $CONFIGPATH | awk '{ print $3 }')
CONNECT_DB_PORT=$(grep 'db_port' $CONFIGPATH | awk '{ print $3 }')
CONNECT_DB_NAME=$(grep 'db_template' $CONFIGPATH | awk '{ print $3 }')
CONNECT_DB_USER=$(grep 'db_user' $CONFIGPATH | awk '{ print $3 }')
CONNECT_DB_PASS=$(grep 'db_password' $CONFIGPATH | awk '{ print $3 }')

#Check if backupdir is mounted.
if ! mountpoint -q "$NFS_MOUNT_BASE"; then
  echo ERROR: "$NFS_MOUNT_BASE" was not mounted. | mail -s "ERRORS - Backup for $HOST" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
  exit 1
fi

# IO redirection for logging.
touch $LOGFILE
exec 6>&1
exec > $LOGFILE
touch $LOGERR
exec 7>&2
exec 2> $LOGERR

_DB_BACKUP() {
  VACUUMDB_LOG=$LOGDIR/$SCRIPT_NAME-Database-VACUUMDB-$(date +%F_%T).log   # vacuumdb log

  if [ "$VACUUM" = "2" ]; then VACUUM_OPT="--analyze"; elif [ "$VACUUM" = "3" ]; then VACUUM_OPT="--analyze --full"; fi
  OPT="--format=c --no-owner"

  if [ ! -d "${DB_BACKUPDIR}/${DBNAME}" ]; then mkdir -p "${DB_BACKUPDIR}/${DBNAME}"; fi

  dump () {
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
  echo Backup Start Time `date`
  echo -e $(yes '=' | head -70 | paste -s -d '' -); echo;
  echo Database Backup for $HOST; echo;
  echo -e $(yes '=' | head -70 | paste -s -d '' -)
  echo Daily Backup of Database \( $DBNAME \)
  echo Rotating last $BACKUP_COPIES Backup...
  REM="$(date +'%A' -d "$BACKUP_COPIES day ago")"
  eval rm -fv "${DB_BACKUPDIR}/${DBNAME}/*.${REM}.dump*"
  echo
  dump "${DBNAME}" "${DB_BACKUPDIR}/${DBNAME}/${DBNAME}_${DATE}.${DOW}.dump"
  compression "${DB_BACKUPDIR}/${DBNAME}/${DBNAME}_${DATE}.${DOW}.dump" &
  wait $!
  echo
  echo Information about database storage:
  echo
  tree -h $DB_BACKUPDIR
  echo
  # Sleep is needed for du to report size along with current backup. 
  sleep 10
  echo -e "Total disk space used for database storage: $(du -hs "$DB_BACKUPDIR" | awk '{print $1}')B / 500GB"
  echo 
  echo -e "Database Backup End Time `date`"
}

_FS_BACKUP() {
  FILESDIR="$(grep "data_dir" "$CONFIGPATH" | awk '{print $3}')"/filestore/"${DBNAME}"
  if [ ! -d "${FS_BACKUPDIR}/${DBNAME}" ]; then mkdir -p "${FS_BACKUPDIR}/${DBNAME}"; fi
  printf '%70s\n' | tr ' ' =
  echo 
  echo "Filestore Backup for $HOST"
  echo 
  printf '%70s\n' | tr ' ' =
  echo `du -hs "$FILESDIR"`
  echo -e "`find ${FILESDIR}/ -type f | wc -l` files in $FILESDIR"
  echo
  rsync ${RSYNC_OPT} ${FILESDIR}/ ${FS_BACKUPDIR}/${DBNAME}/
  printf '%70s\n' | tr ' ' -
  echo -e "ATTACHMENT FILES -> OVH Backup (RSYNC)"
  printf '%70s\n' | tr ' ' -
  echo Information about filestore storage:
  echo
  sleep 10
  echo `du -hs "${FS_BACKUPDIR}/${DBNAME}"`
  echo -e "`find ${FS_BACKUPDIR}/${DBNAME}/ -type f | wc -l` files in ${FS_BACKUPDIR}/${DBNAME}"
  echo
  echo -e "Filestore Backup End Time `date`"
  printf '%70s\n' | tr ' ' =
}

_DB_BACKUP
_FS_BACKUP

#Clean up IO redirection
exec 1>&6 6>&-      # Restore stdout and close file descriptor #6.
exec 1>&7 7>&-      # Restore stdout and close file descriptor #7.
# -s means file is not zero size
if [ -s "$LOGERR" -a -s "$LOGFILE" ]; then
  cat "$LOGERR" | mail -s "ERRORS - Backup for $HOST" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
  cat "$LOGFILE" | mail -s "SUCCESS - Backup for $HOST" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
elif [ -s "$LOGERR" -a ! -s "$LOGFILE" ]; then
  cat "$LOGERR" | mail -s "ERRORS - Backup for $HOST" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
else
  cat "$LOGFILE" | mail -s "SUCCESS - Backup for $HOST" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
fi

find "$LOGDIR"/"${SCRIPT_NAME}"-*.log -type f -mtime +3 -exec rm -f {} +

exit 1