#!/bin/bash
# Maintainer: Sodexis Inc (admin@sodexis.com)
#
# prerequisites: apt-get install postfix mutt heirloom-mailx lrzip tree rsync

CONFIGPATH="/etc/odoo-server-11.conf"
HOST="odoo13.btlps.com"
DBNAME="BTL_Master_V13"
NFS_MOUNT_BASE="/mnt/nfs-backup"
BACKUPDIR="${NFS_MOUNT_BASE}/Filestore"
LOGDIR="/opt/support_files/scripts/logs"
# Email Address to send mail to? (user@domain.com)
MAILADDR="john@sodexis.com"
export REPLYTO="john@sodexis.com"
REPLYTO="john@sodexis.com"
BCC="dailymonitoring@sodexis.com"
RSYNC_OPT="-rlptDuvhW --checksum --delete-after"



#========================= Do not edit below this line ====================================#

SCRIPT_NAME=`basename $0`
FILESDIR="$(grep "data_dir" "$CONFIGPATH" | awk '{print $3}')"/filestore/"${DBNAME}"
LOGFILE=${LOGDIR}/${SCRIPT_NAME}-`date +%m_%d-%H:%M:%S`.log
LOGERR=${LOGDIR}/${SCRIPT_NAME}-ERRORS-`date +%m_%d-%H:%M:%S`.log
WARNING=$LOGDIR/$SCRIPT_NAME-WARNING-`date +%m_%d-%H:%M:%S`.log     # Warning log file.
LOGMAILBODY=${LOGDIR}/${SCRIPT_NAME}-MAILBODY-`date +%m_%d-%H:%M:%S`.log
MUTT="$(which mutt)"

DATE=`date +%Y-%m-%d`
START=$(date "+%s")
#
# IO redirection for logging.
touch $LOGFILE
touch $LOGMAILBODY
exec 6>&1
exec > $LOGFILE
touch $LOGERR
exec 7>&2
exec 2> $LOGERR

if [ ! -d "${FILESDIR}" ]; then
	echo ERROR: $FILESDIR was not found. | mail -s "ERRORS - Odoo Attachment Backup for $HOST" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
    exit 1
fi

if ! mountpoint -q "$NFS_MOUNT_BASE"; then
    echo ERROR: "$NFS_MOUNT_BASE" was not mounted. | mail -s "ERRORS - Odoo Attachment Backup for $HOST" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
    exit 1
fi

if [ ! -d "${BACKUPDIR}/${DBNAME}" ]; then
	mkdir -p "${BACKUPDIR}/${DBNAME}"
fi


echo -e $(yes '=' | head -70 | paste -s -d '' -) | tee -a $LOGMAILBODY
echo | tee -a $LOGMAILBODY
echo "Odoo Attachment Backup for - $HOST" | tee -a $LOGMAILBODY
echo | tee -a $LOGMAILBODY
echo -e $(yes '=' | head -70 | paste -s -d '' -) | tee -a $LOGMAILBODY
echo -e "Backup Start Time `date`" | tee -a $LOGMAILBODY
echo -e $(yes '=' | head -70 | paste -s -d '' -) | tee -a $LOGMAILBODY
echo | tee -a $LOGMAILBODY
echo `du -hs "$FILESDIR"` | tee -a $LOGMAILBODY
echo -e "`find ${FILESDIR}/ -type f | wc -l` files in $FILESDIR" | tee -a $LOGMAILBODY
echo | tee -a $LOGMAILBODY
#
rsync ${RSYNC_OPT} ${FILESDIR}/ ${BACKUPDIR}/${DBNAME}/
echo -e $(yes '=' | head -70 | paste -s -d '' -) | tee -a $LOGMAILBODY
echo | tee -a $LOGMAILBODY
echo -e $(yes '-' | head -120 | paste -s -d '' -) | tee -a $LOGMAILBODY
echo -e "ATTACHMENT FILES -> AWS EBS Storage (RSYNC)" | tee -a $LOGMAILBODY
echo -e $(yes '-' | head -120 | paste -s -d '' -) | tee -a $LOGMAILBODY
echo | tee -a $LOGMAILBODY
echo -e $(yes '=' | head -70 | paste -s -d '' -) | tee -a $LOGMAILBODY
echo Information about Backup Storage.. | tee -a $LOGMAILBODY
echo | tee -a $LOGMAILBODY
sleep 10
echo `du -hs "${BACKUPDIR}/${DBNAME}"` | tee -a $LOGMAILBODY
echo -e "`find ${BACKUPDIR}/${DBNAME}/ -type f | wc -l` files in ${BACKUPDIR}/${DBNAME}" | tee -a $LOGMAILBODY
echo | tee -a $LOGMAILBODY
echo | tee -a $LOGMAILBODY
echo -e "Backup of Attachment to NFS storage completed at `date`" | tee -a $LOGMAILBODY
echo -e $(yes '=' | head -70 | paste -s -d '' -) | tee -a $LOGMAILBODY

lrzip -z $LOGFILE

echo Attachments: "${LOGFILE}".lrz | tee -a $LOGMAILBODY
exec 1>&6 6>&-      # Restore stdout and close file descriptor #6.
exec 1>&7 7>&-      # Restore stdout and close file descriptor #7.

if [ -s "$LOGERR" -a -s "$LOGFILE" ]; then
    cat "$LOGERR" | mail -s "ERRORS - Odoo Attachment Backup for $HOST" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
    cat "$LOGMAILBODY" | $MUTT -a "${LOGFILE}".lrz -s "SUCCESS - Odoo Attachment Backup for $HOST" -- "$BCC" "$MAILADDR"
elif [ -s "$LOGERR" -a ! -s "$LOGFILE" ]; then
    cat "$LOGERR" | mail -s "ERRORS - Odoo Attachment Backup for $HOST" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
else
    cat "$LOGMAILBODY" | $MUTT -a "${LOGFILE}".lrz -s "SUCCESS - Odoo Attachment Backup for $HOST" -- "$BCC" "$MAILADDR"
fi

if [ -s "$LOGERR" ]; then
    STATUS=1
else
    STATUS=0
fi

find "$LOGDIR"/"${SCRIPT_NAME}"-*.log -type f -mtime +3 -exec rm -f {} +
find "$LOGDIR"/"${SCRIPT_NAME}"-*.lrz -type f -mtime +3 -exec rm -f {} +

exit $STATUS
