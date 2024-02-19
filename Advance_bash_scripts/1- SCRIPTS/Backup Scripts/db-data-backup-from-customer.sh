#!/bin/bash
# Maintainer: Sodexis Inc (admin@sodexis.com)
# Description: This script rsync backup of database and filestore from customer server to sodexis backup. 
# prerequisites: apt-get install postfix mutt s-nail lrzip tree rsync && ln -s /usr/bin/s-nail /usr/bin/mail
# Extract dump: bzip2 -dk <dump>.bz2
# Note:
# copy /root/.ssh/id_rsa.pub key to the remove server sodexis user (/home/sodexis/.ssh/authorized_keys) and test the login from Proxmox Backup(105)container.
# Create .hushlogin on the user home directory created on the backup server and try ssh -p port user@remote_host from the backup server to accept the SSH authorization.
# Create REMOTE_TEMP: mkdir -p /Backup/Database/ && chown sodexis: /Backup/Database

# Database specific
CUST_NAME="Matthews"      # Without space.
DB_NAME="MAT_Master_V13"
REMOTE_CONF_NAME="/opt/odoo-13/conf/odoo.conf"
REMOTE_DATA_DIR="/opt/odoo-13/data"
REMOTE_TEMP="/Backup/Database"       # Create this directory in remote server.
SSH_USER="sodexis"
SSH_PORT="2258"
SSH_IP="209.16.138.29"
VACUUM=2              # 0: No vacuum, 1:vacuum only, 2: vacuum and analyze, 3: Full vacuum.
BACKUP_COPIES=5       # No of days to keep backup copies.
MAILADDR="john@sodexis.com"
export REPLYTO="john@sodexis.com"
REPLYTO="john@sodexis.com"
BCC="john@sodexis.com"


#====================== Do not edit below this line ======================================#

RSYNC_OPT="-qrlptDuvhW --checksum --delete-after"
DESTINATION_DIR=/var/lib/vz/customer_backups/${CUST_NAME}
DATE=`date +%F_%T`            # Datestamp e.g 2002-09-21
DOW=`date +%A`
LOGDIR="/opt/support_files/scripts/logs"
LOGFILE=${LOGDIR}/${CUST_NAME}-Backup-$(date +%F_%T).log
LOGERR=${LOGDIR}/${CUST_NAME}-Backup-ERRORS-$(date +%F_%T).log

if [[ "$VACUUM" = "2" ]]; then VACUUM_OPT="--analyze"; elif [[ "$VACUUM" = "3" ]]; then VACUUM_OPT="--analyze --full"; fi
if [[ ! -d "$DESTINATION_DIR/Database" ]]; then
  mkdir -p ${DESTINATION_DIR}/Database
fi
if [[ ! -d "$DESTINATION_DIR/Filestore" ]]; then
  mkdir -p ${DESTINATION_DIR}/Filestore
fi

# IO redirection for logging.
touch $LOGFILE
exec 6>&1
exec > $LOGFILE
touch $LOGERR
exec 7>&2
exec 2> $LOGERR


printf '%80s\n' | tr ' ' =
echo Backup Start Time `date`
printf '%80s\n' | tr ' ' =
echo
echo Database Backup for $CUST_NAME Production
echo
printf '%80s\n' | tr ' ' =
echo Daily Backup of Database \( $DB_NAME \)
echo Rotating last $BACKUP_COPIES Backup...
ssh -q -o 'BatchMode=yes' -p ${SSH_PORT} ${SSH_USER}@${SSH_IP} 'bash -s' <<-END
  CONNECT_DB_IP=\$(grep 'db_host' ${REMOTE_CONF_NAME} | awk '{ print \$3 }')
  CONNECT_DB_PORT=\$(grep 'db_port' ${REMOTE_CONF_NAME} | awk '{ print \$3 }')
  CONNECT_DB_NAME=\$(grep 'db_template' ${REMOTE_CONF_NAME} | awk '{ print \$3 }')
  CONNECT_DB_USER=\$(grep 'db_user' ${REMOTE_CONF_NAME} | awk '{ print \$3 }')
  CONNECT_DB_PASS=\$(grep 'db_password' ${REMOTE_CONF_NAME} | awk '{ print \$3 }')
  REM="\$(date +'%A' -d "$BACKUP_COPIES day ago")"
  eval rm -fv "${REMOTE_TEMP}/*.\${REM}.dump*"
  echo
  START_VAC=\$(date +"%s")
  if [ "$VACUUM" -eq "2" ]; then 
    echo -n "VACUUMDB (ANALYZE): "
  elif [ "$VACUUM" -eq "3" ]; then
    echo -n "VACUUMDB (FULL, ANALYZE): "
  else
    echo -n "VACUUMDB: "
  fi
  PGPASSWORD=\$CONNECT_DB_PASS vacuumdb -U \${CONNECT_DB_USER} -h \${CONNECT_DB_IP} -p \${CONNECT_DB_PORT} -q -w ${VACUUM_OPT} ${DB_NAME} > /dev/null 2>&1 && END_VAC=\$(date +"%s") && echo -e "DONE"
  TOT_VAC_TIME=\$((\$END_VAC-\$START_VAC))
  echo -e "Time taken for vacuumdb: \$((\$TOT_VAC_TIME / 60)) minutes and \$((\$TOT_VAC_TIME % 60)) seconds"
  echo
  PGPASSWORD=\$CONNECT_DB_PASS pg_dump -U \${CONNECT_DB_USER} -h \${CONNECT_DB_IP} -p \${CONNECT_DB_PORT} -w -O ${DB_NAME} > ${REMOTE_TEMP}/${DB_NAME}_${DATE}.${DOW}.dump
  echo Compression information of "${REMOTE_TEMP}/${DB_NAME}_${DATE}.${DOW}.dump.bz2"
  bzip2 -f -v ${REMOTE_TEMP}/${DB_NAME}_${DATE}.${DOW}.dump 2>&1 && echo
  du -hs "${REMOTE_DATA_DIR}/filestore/${DB_NAME}" > ${REMOTE_TEMP}/count.txt
  echo \$(find ${REMOTE_DATA_DIR}/filestore/${DB_NAME}/ -type f | wc -l) files in ${REMOTE_DATA_DIR}/filestore/${DB_NAME} >> ${REMOTE_TEMP}/count.txt
END
if [[ "$?" -ne "0" ]]; then
  echo -e "Unable to login to "${CUST_NAME}" Server\nBackup cancelled" | mail -s "ERRORS - Backup for ${CUST_NAME} Production" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
  exit 1
fi

rsync ${RSYNC_OPT} -e "ssh -p ${SSH_PORT}" ${SSH_USER}@${SSH_IP}:${REMOTE_TEMP}/ ${DESTINATION_DIR}/Database/
TMPDIR=$(mktemp -d -p /tmp)
mv ${DESTINATION_DIR}/Database/count.txt ${TMPDIR}/
echo Information about Database storage:
echo
tree -h ${DESTINATION_DIR}/Database
echo
echo -e "Database Backup End Time `date`"
printf '%80s\n' | tr ' ' =
echo
echo "Filestore Backup for $CUST_NAME Production"
echo
printf '%80s\n' | tr ' ' =
cat -v ${TMPDIR}/count.txt
TT=$(echo $TMPDIR | cut -d/ -f3)
if [ -d /tmp/$TT ]; then rm -rf /tmp/${TT}; fi
echo
printf '%140s\n' | tr ' ' -
echo -e "Filestore -> Sodexis Backup (RSYNC)"
printf '%140s\n' | tr ' ' -
rsync ${RSYNC_OPT} -e "ssh -p ${SSH_PORT}" ${SSH_USER}@${SSH_IP}:${REMOTE_DATA_DIR}/filestore/${DB_NAME}/ ${DESTINATION_DIR}/Filestore/
echo Information about Filestore storage:
echo
du -hs ${DESTINATION_DIR}/Filestore
echo $(find ${DESTINATION_DIR}/Filestore/ -type f | wc -l) files in ${DESTINATION_DIR}/Filestore
echo
echo -e "Filestore Backup End Time `date`"
printf '%80s\n' | tr ' ' =

#Clean up IO redirection
exec 1>&6 6>&-      # Restore stdout and close file descriptor #6.
exec 1>&7 7>&-      # Restore stdout and close file descriptor #7.
# -s means file is not zero size
if [ -s "$LOGERR" -a -s "$LOGFILE" ]; then
  cat "$LOGERR" | mail -s "ERRORS - Backup for $CUST_NAME Production" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
  cat "$LOGFILE" | mail -s "SUCCESS - Backup for $CUST_NAME Production" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
elif [ -s "$LOGERR" -a ! -s "$LOGFILE" ]; then
  cat "$LOGERR" | mail -s "ERRORS - Backup for $CUST_NAME Production" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
else
  cat "$LOGFILE" | mail -s "SUCCESS - Backup for $CUST_NAME Production" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
fi

find "$LOGDIR"/"${CUST_NAME}"-*.log -type f -mtime +3 -exec rm -f {} +

exit 1