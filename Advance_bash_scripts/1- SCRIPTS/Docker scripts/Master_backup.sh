#!/bin/bash
BACKUPDIR="/mnt/ftp-backup"
N=5
C1=( 'ncctest12-odoo' 'bK8q4l!yqeQoz3y9tMET' 'NCC_Master' )
C2=( 'hentest12-odoo' '!4VRP5MRktwzQ8$eir$4' 'HEN_Master' )

BACKUP_COPIES=5
LOGDIR="/opt/support_files/scripts/logs"
MAILADDR="john@sodexis.com"
export REPLYTO="john@sodexis.com"
REPLYTO="john@sodexis.com"
BCC="dailymonitoring@sodexis.com"
SCRIPT_NAME=`basename $0`

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

for ((i = 1; i <= N; i++)); do
  #Check for commented server.
  TMP_CT=C${i}
  CT=("${!TMP_CT}")
  if [ ! -z "${CT}" ]; then
    TMP_AR="C$i[@]"
    AR=("${!TMP_AR}")
    if [ "${#AR[@]}" -ne "3" ]; then
      echo "Skipping the container "$TMP_CT". An error found in values"
      continue
    fi
    CT_IP="$(docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${AR[0]})"
    if [[ ! -d "${BACKUPDIR}/${AR[0]}" ]]; then mkdir -p "${BACKUPDIR}/${AR[0]}"; fi 
    cd ${BACKUPDIR}/${AR[0]}/
    echo -e "$LINE_E"
    echo -en "Backup Database for ${AR[0]}: "
    (curl --silent --show-error --fail \
          -X POST \
          -F "master_pwd=${AR[1]}" \
          -F "name=${AR[2]}" \
          -F 'backup_format=zip' \
          -o ${AR[2]}_$(date +%F_%T)_$(date +%A).zip \
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
    eval rm -fv "${BACKUPDIR}/${AR[0]}/*_${REM}.zip"
    echo
    tree -h "$BACKUPDIR"/"${AR[0]}"
  echo -e "$LINE_E"
  fi
  echo
done

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

