#!/bin/bash
# Maintainer: Sodexis Inc (admin@sodexis.com)
# Description: This script rsync backup of database and filestore from customer server to sodexis backup. 
# prerequisites: apt-get install postfix mutt s-nail lrzip tree rsync && ln -s /usr/bin/s-nail /usr/bin/mail
# Extract dump: bzip2 -dk <dump>.bz2
# Note:
# Create .hushlogin on the user home directory created on the backup server.
#
#
# Create a settings file under script directory/backup-script-settings/<settingsfile_name>.settings with the following settings. 
# run script: ./backup.sh <settingsfile_name>
#
# For kubenetes. Create user sodexis in cluster if not created. 
#   sudo usermod -a -G microk8s sodexis
#   sudo chown -f -R sodexis ~/.kube

#
# ============ Settings file example Begin ================
# CUST_NAME="TigerPackaging"
# DB_NAME="TP_Master_V12"
#
## If deployment is running in kubernetes
# IS_KUBERNETES_DEPLOY="no"                             # yes/no
# KUBERNETES_NAMESPACE="lasiestag-production"
# KUBERNETES_TEMP_CONFPATH="/tmp/lasg-odoo.conf"
# KUBERNETES_DATA_DIR="/var/snap/microk8s/common/default-storage/lasiestag-production-production-auto-deploy-filestore-pvc-*"
#
## If deployment is running in docker or standalone server
# REMOTE_CONF_NAME="/opt/odoo/tpprod12-odoo/conf/odoo.conf"
# REMOTE_DATA_DIR="/opt/odoo/tpprod12-odoo/data/filestore"
#
# REMOTE_TEMP="/Backup/Database/Tigerpackaging"       # Create this directory in remote server.
# SSH_USER="sodexis"
# SSH_PORT="2258"
# SSH_IP="proserv-eu.sodexis.com"
# POSTGRES_CLIENT_BASE="/usr/lib/postgresql/13/bin"
# VACUUM=2              # 0: No vacuum, 1:vacuum only, 2: vacuum and analyze, 3: Full vacuum.
# BACKUP_COPIES=5       # No of days to keep backup copies.
# MAILADDR="dailymonitoring@sodexis.com"
# export REPLYTO="john@sodexis.com"
# REPLYTO="john@sodexis.com"
# BCC="john@sodexis.com"
# ============ Settings file example End ==================
#
#
#
#
#====================== Do not edit below this line ======================================#
SETTINGS_FILE="$(dirname $(readlink -f $0))"/backup-script-settings/${1}
if [ ! -f "$SETTINGS_FILE" ]; then
  echo "The script could not find the $SETTINGS_FILE"
  echo "Aborting."
  exit 1
fi
set -a
source "$SETTINGS_FILE"
set +a

RSYNC_OPT="-qrlptDuvhW --checksum --delete-after"
DESTINATION_DIR=/BACKUP/${CUST_NAME}
DATE=`date +%F_%T`            # Datestamp e.g 2002-09-21
DOW=`date +%A`
LOGDIR="/opt/support_files/scripts/logs"
LOGFILE=${LOGDIR}/${CUST_NAME}-Backup-$(date +%F_%T).log
LOGERR=${LOGDIR}/${CUST_NAME}-Backup-ERRORS-$(date +%F_%T).log

if [[ "$VACUUM" = "2" ]]; then VACUUM_OPT="--analyze"; elif [[ "$VACUUM" = "3" ]]; then VACUUM_OPT="--analyze --full"; fi
if [[ "${IS_KUBERNETES_DEPLOY}" == "yes" ]]; then DATA_DIR=${KUBERNETES_DATA_DIR}; else DATA_DIR=${REMOTE_DATA_DIR}; fi

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
  if [[ ! -d "$REMOTE_TEMP" ]]; then
    mkdir -p $REMOTE_TEMP
    if [[ ! -d "$REMOTE_TEMP" ]]; then
      echo "Unable to create $REMOTE_TEMP directory. Create using root and chown sodexis: $REMOTE_TEMP"
      exit 1
    fi
  fi
  if [[ "${IS_KUBERNETES_DEPLOY}" == "yes" ]]; then
    /snap/bin/kubectl cp ${KUBERNETES_NAMESPACE}/\$(/snap/bin/kubectl get pods --no-headers -o custom-columns=":metadata.name" -l app=production -n ${KUBERNETES_NAMESPACE}):odoo/conf/odoo.cfg $KUBERNETES_TEMP_CONFPATH > /dev/null 2>&1
    if [[ -s "${KUBERNETES_TEMP_CONFPATH}" ]]; then
      CONF_NAME=${KUBERNETES_TEMP_CONFPATH}
      CONNECT_DB_IP=\$(grep 'db_host' \${CONF_NAME} | awk '{ print \$3 }').$KUBERNETES_NAMESPACE
    else
      echo "Unable to find $KUBERNETES_TEMP_CONFPATH file. check "kubectl cp" in the backup script"
      exit 1
    fi
  else
    CONF_NAME=${REMOTE_CONF_NAME}
    CONNECT_DB_IP=\$(grep 'db_host' \${CONF_NAME} | awk '{ print \$3 }')
  fi

  CONNECT_DB_PORT=\$(grep 'db_port' \${CONF_NAME} | awk '{ print \$3 }')
  CONNECT_DB_NAME=template1
  CONNECT_DB_USER=\$(grep 'db_user' \${CONF_NAME} | awk '{ print \$3 }')
  CONNECT_DB_PASS=\$(grep 'db_password' \${CONF_NAME} | awk '{ print \$3 }')

  # Debug
  #echo "\$CONF_NAME | \$CONNECT_DB_IP | \$CONNECT_DB_PORT | \$CONNECT_DB_NAME | \$CONNECT_DB_USER | \$CONNECT_DB_PASS" > /tmp/1.txt
  #exit 1

  echo
  START_VAC=\$(date +"%s")
  if [ "$VACUUM" -eq "2" ]; then 
    echo -n "VACUUMDB (ANALYZE): "
  elif [ "$VACUUM" -eq "3" ]; then
    echo -n "VACUUMDB (FULL, ANALYZE): "
  else
    echo -n "VACUUMDB: "
  fi

  PGPASSWORD=\$CONNECT_DB_PASS ${POSTGRES_CLIENT_BASE}/vacuumdb -U \${CONNECT_DB_USER} -h \${CONNECT_DB_IP} -p \${CONNECT_DB_PORT} -q -w ${VACUUM_OPT} ${DB_NAME} > /dev/null 2>&1 && END_VAC=\$(date +"%s") && echo -e "DONE"
  TOT_VAC_TIME=\$((\$END_VAC-\$START_VAC))
  echo -e "Time taken for vacuumdb: \$((\$TOT_VAC_TIME / 60)) minutes and \$((\$TOT_VAC_TIME % 60)) seconds"
  echo
  PGPASSWORD=\$CONNECT_DB_PASS ${POSTGRES_CLIENT_BASE}/pg_dump -U \${CONNECT_DB_USER} -h \${CONNECT_DB_IP} -p \${CONNECT_DB_PORT} -w -O ${DB_NAME} > ${REMOTE_TEMP}/${DB_NAME}_${DATE}.${DOW}.dump
  echo Compression information of "${REMOTE_TEMP}/${DB_NAME}_${DATE}.${DOW}.dump.bz2"
  bzip2 -f -v ${REMOTE_TEMP}/${DB_NAME}_${DATE}.${DOW}.dump 2>&1 && echo
  du -hs ${DATA_DIR}/${DB_NAME} > ${REMOTE_TEMP}/count.txt
  echo \$(find ${DATA_DIR}/${DB_NAME}/ -type f | wc -l) files in ${DATA_DIR}/${DB_NAME} >> ${REMOTE_TEMP}/count.txt
END
if [[ "$?" -ne "0" ]]; then
  echo -e "Unable to login to "${CUST_NAME}" Server\nBackup cancelled" | mail -s "ERRORS - Backup for ${CUST_NAME} Production" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
  exit 1
fi

rsync ${RSYNC_OPT} --remove-source-files -e "ssh -p ${SSH_PORT}" ${SSH_USER}@${SSH_IP}:${REMOTE_TEMP}/${DB_NAME}_${DATE}.${DOW}.dump.bz2 :${REMOTE_TEMP}/count.txt ${DESTINATION_DIR}/Database/
# Just to avoid old count.txt. we are moving it to temp and later delete it
TMPDIR=$(mktemp -d -p /tmp)
mv ${DESTINATION_DIR}/Database/count.txt ${TMPDIR}/
# Rotating backup in destination
rm $(ls -t "${DESTINATION_DIR}"/Database/* | awk "NR>${BACKUP_COPIES}") > /dev/null 2>&1
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
rsync ${RSYNC_OPT} -e "ssh -p ${SSH_PORT}" ${SSH_USER}@${SSH_IP}:${DATA_DIR}/${DB_NAME}/ ${DESTINATION_DIR}/Filestore/
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