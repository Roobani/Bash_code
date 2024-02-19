#!/bin/bash
# Auther: John, Sodexis
# This script loop through all the available docker container and Backup the databases name ending with Master, or Master_V1*.
# This also check and delete for 30 days old database directories.
# apt-get install tree curl

BACKUPDIR="/mnt/ftp-backup"
BACKUP_COPIES=5
LOGDIR="/opt/support_files/scripts/logs"
MAILADDR="john@sodexis.com"
export REPLYTO="john@sodexis.com"
REPLYTO="john@sodexis.com"
BCC="dailymonitoring@sodexis.com"
SCRIPT_NAME=`basename $0`
ODOO_DATABASE_MANAGEMENT_PASS=5s4pQXpP1Vb2I5fgp1C2
POSTGRES_PASS=4x3V4476uR
EXCLUDE_CT=(demo-odoo custdemo12-odoo custdemo13-odoo)

#=============== Don't Edit anything below =================

LOGFILE=${LOGDIR}/${SCRIPT_NAME}-$(date +%F_%T).log
LOGERR=${LOGDIR}/${SCRIPT_NAME}-ERRORS-$(date +%F_%T).log

# IO redirection for logging.
touch $LOGFILE
exec 6>&1
exec > $LOGFILE
touch $LOGERR
exec 7>&2
exec 2> $LOGERR

if ! mountpoint -q "$BACKUPDIR"; then
  echo ERROR: "$BACKUPDIR" was not mounted. | mail -s "ERRORS - Odoo Attachment Backup for $HOST" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
  exit 1
fi

LINE_E=$(printf -v sep '%*s' 50 ; echo "${sep// /=}")

CTNAME=(`docker ps --format "{{.Names}}" -f name=odoo`)

for ((i = 0; i < ${#CTNAME[@]}; i++)); do
  if [[ "${EXCLUDE_CT[@]}" =~ "${CTNAME[$i]}" ]]; then
    continue
  fi	
  CT_NAME="$(echo ${CTNAME[$i]} | cut -d- -f1)"
  CT_IP="$(docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${CTNAME[$i]})"
  DBNAME=(`PGPASSWORD=${POSTGRES_PASS} psql -h ${CT_NAME}-postgres -p 5432 -d template1 -U sodexis -w --tuples-only -P format=unaligned -c "select datname from pg_database where datdba=(select usesysid from pg_user where usename = 'sodexis')"`);
  for DB in ${DBNAME[@]}; do
    if [[ "$DB" =~ Master$ ]] || [[ "$DB" =~ Master_V1[0-9-]$ ]]; then
      if [[ ! -d "${BACKUPDIR}/${CTNAME[$i]}" ]]; then mkdir -p "${BACKUPDIR}/${CTNAME[$i]}"; fi
      cd ${BACKUPDIR}/${CTNAME[$i]}/
      echo
      echo -e "$LINE_E"
      echo -en "Backup Database for ${CTNAME[$i]}: "
      (curl --silent --show-error --fail \
            -X POST \
            -F "master_pwd=${ODOO_DATABASE_MANAGEMENT_PASS}" \
            -F "name=${DB}" \
            -F 'backup_format=zip' \
            -o ${DB}_$(date +%F_%T)_$(date +%A).zip \
            http://${CT_IP}:8069/web/database/backup) &
      wait $!
      ret=$?
      if [[ "$ret" -eq "0" ]]; then
        echo -e "DONE"
      else
        echo -e "ERROR exit code: $ret" | tee "$LOGERR"
      fi
      echo -e "$LINE_E"
      echo Rotating last $BACKUP_COPIES Backup...
      REM="$(date +'%A' -d "$BACKUP_COPIES day ago")"
      eval rm -fv "${BACKUPDIR}/${CTNAME[$i]}/*_${REM}.zip"
      echo
      tree -h "$BACKUPDIR"/"${CTNAME[$i]}"
    fi
  done
done
echo; echo
echo Deleting 30 days old obsolete backup directories...
echo -e "$LINE_E"
for d in $(find $BACKUPDIR -maxdepth 1 -type d -mtime +30); do
  if [ ! -z $d ]; then
    MATCH=$(basename $d)
    if [[ "$MATCH" =~ odoo$ ]]; then
      eval rm -rfv $d
    else
      echo "Nothing to delete."
    fi
  else
    echo "Nothing to delete."
  fi
done
echo -e "$LINE_E"

#Clean up IO redirection
exec 1>&6 6>&-      # Restore stdout and close file descriptor #6.
exec 1>&7 7>&-      # Restore stdout and close file descriptor #7.
# -s means file is not zero size
if [ -s "$LOGERR" -a -s "$LOGFILE" ]; then
  cat "$LOGERR" | mail -s "ERRORS - Pre-Production Backup" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
  cat "$LOGFILE" | mail -s "SUCCESS - Pre-Production Backup" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
elif [ -s "$LOGERR" -a ! -s "$LOGFILE" ]; then
  cat "$LOGERR" | mail -s "ERRORS - Pre-Production Backup" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
else
  cat "$LOGFILE" | mail -s "SUCCESS - Pre-Production Backup" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
fi

find "$LOGDIR"/"${SCRIPT_NAME}"-*.log -type f -mtime +3 -exec rm -f {} +