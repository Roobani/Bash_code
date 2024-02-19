#!/bin/bash

#Maintainer: John, admin@sodexis.com
#Description: This script will do -u all for all the databases in all the available 
#       running docker containers.

SCRIPT_NAME=`basename $0`
INCLUDE_CT=(mattest13-odoo)
EXCLUDE_CT=(demo12-odoo sodtest11-odoo lstest10-odoo)      # Space seperated container name.
DO_MASTER_ONLY=yes                    # Do -u all on found database ending with Master or Master_V13.
ERROR_MAILADDR='xavier@sodexis.com karthik@sodexis.com ksuganthi@sodexis.com atchuthan@sodexis.com'
MAILADDR="dailymonitoring@sodexis.com"
export REPLYTO="john@sodexis.com"
BCC="john@sodexis.com"
MUTT="$(which mutt)"
LOGDIR="/opt/support_files/scripts/logs"
ODOO_USER="sodexis"


#=============================== DON'T EDIT BELOW ===========================================#

UPDATEINSEC="1200"
UPDATE_CONTEXT="Initiating shutdown"

if [[ ! -z "$INCLUDE_CT" ]]; then 
  CTNAME=(${INCLUDE_CT[@]})
else
  CTNAME=(`docker ps --format "{{.Names}}" -f name=odoo`)
fi

for ((i = 0; i <= ${#CTNAME[@]}; ++i)); do
  if [[ "${EXCLUDE_CT[@]}" =~ "${CTNAME[$i]}" ]]; then
    continue
  fi
  LOGFILE="$LOGDIR/${SCRIPT_NAME}_${CTNAME[$i]}_$(date +%F_%T).log"             # Logfile Name
  LOGERR="$LOGDIR/${SCRIPT_NAME}_${CTNAME[$i]}-ERRORS_$(date +%F_%T).log"       # Logfile Name
  UK_ER_STATUS="$LOGDIR/${SCRIPT_NAME}_${CTNAME[$i]}-UK_ER_STATUS_$(date +%F_%T).log"
  CT_HOST_NAME="$(docker exec ${CTNAME[$i]} env | grep VIRTUAL_HOST | cut -d'=' -f2)"
  CONFIGPATH="/opt/odoo/${CTNAME[$i]}/conf/odoo.conf"
  CONNECT_DB_IP=$(grep 'db_host' $CONFIGPATH | awk '{ print $3 }')
  CONNECT_DB_PORT=$(grep 'db_port' $CONFIGPATH | awk '{ print $3 }')
  CONNECT_DB_NAME=$(grep 'db_template' $CONFIGPATH | awk '{ print $3 }')
  CONNECT_DB_USER=$(grep 'db_user' $CONFIGPATH | awk '{ print $3 }')
  CONNECT_DB_PASS=$(grep 'db_password' $CONFIGPATH | awk '{ print $3 }')
  DBNAME=(`PGPASSWORD=$CONNECT_DB_PASS psql -h $CONNECT_DB_IP -p $CONNECT_DB_PORT -d $CONNECT_DB_NAME -U $CONNECT_DB_USER -w --tuples-only -P format=unaligned -c "select datname from pg_database where datdba=(select usesysid from pg_user where usename = '${CONNECT_DB_USER}')"`);
  LOG="/opt/odoo/${CTNAME[$i]}/logs/odoo-server.log"
  SKIP=false
  LOCKFILE=/var/lock/$(echo ${CTNAME[$i]} | cut -d- -f1)*

  # IO redirection for logging.
  touch $LOGFILE
  exec 6>&1
  exec > $LOGFILE
  touch $LOGERR
  exec 7>&2
  exec 2> $LOGERR

  if [[ -f "${LOCKFILE%?}_auto-db-update.lock" ]]; then
    /bin/date | /usr/bin/mail -s "ERRORS - Auto-update for ${CT_HOST_NAME}, Lockfile already present" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
    continue
  fi

  # lockfile
  touch "${LOCKFILE%?}_auto-db-update.lock"
  chown ${ODOO_USER}: ${LOCKFILE%?}_auto-db-update.lock

  if grep -q "http_enable" ${CONFIGPATH}; then
    sed -i "s|^\(http_enable\s*=\s*\).*\$|\1False|" $CONFIGPATH
    sed -i "s|^\(max_cron_threads\s*=\s*\).*\$|\10|" $CONFIGPATH
  else
    sed -i "s|^\(xmlrpc\s*=\s*\).*\$|\1False|" $CONFIGPATH
    sed -i "s|^\(max_cron_threads\s*=\s*\).*\$|\10|" $CONFIGPATH
  fi
  if [[ "$(grep -w 'http_enable\|xmlrpc' $CONFIGPATH | awk '{ print $3 }')" != "False" ]]; then
    echo -e "ERROR: Unable to disable the Odoo listener. Check the 'http_enable'/'xmlrpc' parameter in odoo configuration file\n\
    This Test server database update has been skipped."  >> $LOGERR
    SKIP=true
  elif [[ "$(grep -w 'max_cron_threads' $CONFIGPATH | awk '{ print $3 }')" -ne "0" ]]; then
    echo -e "ERROR: Unable to disable the cron worker. Check the 'max_cron_threads' parameter in odoo configuration file\n\
    This Test server database update has been skipped."  >> $LOGERR
    SKIP=true
  fi

  if ! ${SKIP}; then
    docker restart -t 30 ${CTNAME[$i]} >/dev/null 2>&1
    sleep 5
    if ! $(docker inspect --format="{{ .State.Running }}" ${CTNAME[$i]} 2> /dev/null); then
      echo "ERROR: Unable to restart the container after disabling the http and cron.\n\
      This Test server datebase update has been skipped." >> $LOGERR
      SKIP=true
    fi
    echo " "
    if ! ${SKIP}; then
      for DBI in ${!DBNAME[*]}; do
        if [[ "$DO_MASTER_ONLY" == "yes" ]]; then
          if [[ "${DBNAME[$DBI]}" =~ Master$ ]] || [[ "${DBNAME[$DBI]}" =~ Master_V1[0-9-]$ ]]; then
            :
          else
            continue
          fi
        fi
        REPEAT=0
        UPDATE_TMP_LOG="/tmp/${DBNAME[$DBI]}-u-all.log"
        docker exec -u ${ODOO_USER} -d -it ${CTNAME[$i]} ./entrypoint.sh update ${DBNAME[$DBI]}
        (/usr/bin/timeout $UPDATEINSEC sed "/$UPDATE_CONTEXT/q" > "$UPDATE_TMP_LOG" < <(tail -fn0 "$LOG")) &
        wait $!
        if [[ "$?" -eq "124" ]]; then
          REPEAT=1
        elif grep -oq 'ERROR' $UPDATE_TMP_LOG; then
          REPEAT=1
        else
          echo -e "Updating modules for database '${DBNAME[$DBI]}': DONE"
        fi
        if [[ "$REPEAT" -eq "1" ]]; then
          docker exec -u ${ODOO_USER} -d -it ${CTNAME[$i]} ./entrypoint.sh update ${DBNAME[$DBI]}
          (/usr/bin/timeout $UPDATEINSEC sed "/$UPDATE_CONTEXT/q" > "$UPDATE_TMP_LOG" < <(tail -fn0 "$LOG")) &
          wait $!
          if [[ "$?" -eq "124" ]]; then
            echo -e "Updating modules for database '${DBNAME[$DBI]}': TIMEOUT after second -u all" | tee -a $UK_ER_STATUS
            UK_DB_LOG="$UK_DB_LOG -a $UPDATE_TMP_LOG"
          elif grep -oq 'ERROR' $UPDATE_TMP_LOG; then
            echo -e "Updating modules for database '${DBNAME[$DBI]}': ERROR after second -u all" | tee -a $UK_ER_STATUS
            ER_DB_LOG="$ER_DB_LOG -a $UPDATE_TMP_LOG"
          else
            echo -e "Updating modules for database '${DBNAME[$DBI]}': DONE afer second -u all"
          fi
        fi
      done
      sed -i 's:^\(\(http_enable\|xmlrpc\)\s*=\s*\).*$:\1True:' $CONFIGPATH
      sed -i "s|^\(max_cron_threads\s*=\s*\).*\$|\11|" $CONFIGPATH
      docker restart -t 30 ${CTNAME[$i]} >/dev/null 2>&1
      echo -e " "
      echo -e "Databases update completed."
    fi
  fi
  # Clean up IO redirection
  exec 1>&6 6>&-      # Restore stdout and close file descriptor #6.
  exec 1>&7 7>&-      # Restore stdout and close file descriptor #7.

  # Remove lock file.
  rm "${LOCKFILE%?}_auto-db-update.lock" >/dev/null 2>&1

  # General Script log errors.
  if [[ -s "$LOGERR" ]]; then
    cat "$LOGERR" | /usr/bin/mail -s "ERROR - Auto-update Execution" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
  fi
  if [[ -s "$UK_ER_STATUS" ]]; then
    echo " " >> $UK_ER_STATUS
    echo "The ERRORS log file(s) are attached." >> $UK_ER_STATUS
    cat "$UK_ER_STATUS" | $MUTT $UK_DB_LOG $ER_DB_LOG -s "ERRORS - Auto-update for $CT_HOST_NAME" -- $MAILADDR $BCC $ERROR_MAILADDR
  fi
  UK_DB_LOG=''
  ER_DB_LOG=''
done

# Clean up Logfile
find "$LOGDIR"/"${SCRIPT_NAME}"_*.log -type f -mtime +3 -exec rm -f {} +