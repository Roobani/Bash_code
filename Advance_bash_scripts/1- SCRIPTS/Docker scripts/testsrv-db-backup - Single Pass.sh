#1/bin/bash
# This script requires database management password as argument.

#Exclude servers. Add servers name seperated by space. eg: etstest11-odoo lstest10-odoo
EXCLUDE_SERVER=""
#Include servers. Add servers name seperated by space. eg: etstest11-odoo lstest10-odoo
INCLUDE_SERVER=()
#
NEWER_DB_ONLY=0       ## 0: disable, 1: enable
#
BACKUPDIR="/Backup/$(date +%F_%T)"


if [[ -z "$1" ]]; then echo "Enter the database management password as argument enclosed with single quote"; exit 1; fi

LINE_E=$(printf -v sep '%*s' 50 ; echo "${sep// /=}")

if [ ! -d "$BACKUPDIR" ]; then mkdir -p $BACKUPDIR; fi

for seq in {8..14}; do 
  CTNAME+=(`docker ps $ps_arg --format "{{.Names}}" -f name=${seq}-odoo | sort`)
done

if [[ ! -z "$INCLUDE_SERVER" ]]; then CTNAME=(${INCLUDE_SERVER[@]}); fi

for ((i = 0; i < ${#CTNAME[@]}; ++i)); do
  if [ ! -z "$EXCLUDE_SERVER" ]; then
    if grep -qw "${CTNAME[$i]}" <<< "$EXCLUDE_SERVER"; then
      continue
    fi
  fi
  echo -e '\E[38;5;10m'"$LINE_E \e[00m"
  echo -e '\E[38;5;10m'"Backup Database for ${CTNAME[$i]}:\e[00m"
  CONFIG="/opt/odoo/${CTNAME[$i]}/conf/odoo.conf"
  CT_IP="$(docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${CTNAME[$i]})"
  CONNECT_DB_IP=$(grep 'db_host' $CONFIG | awk '{ print $3 }')
  CONNECT_DB_PORT=$(grep 'db_port' $CONFIG | awk '{ print $3 }')
  CONNECT_DB_NAME=$(grep 'db_template' $CONFIG | awk '{ print $3 }')
  CONNECT_DB_USER=$(grep 'db_user' $CONFIG | awk '{ print $3 }')
  CONNECT_DB_PASS=$(grep 'db_password' $CONFIG | awk '{ print $3 }')
  DBNAME=(`PGPASSWORD=$CONNECT_DB_PASS psql -h $CONNECT_DB_IP -p $CONNECT_DB_PORT -d $CONNECT_DB_NAME -U $CONNECT_DB_USER -w --tuples-only -P format=unaligned -c "select datname from pg_database where datdba=(select usesysid from pg_user where usename = '${CONNECT_DB_USER}')"`);
  if [[ -z "$DBNAME" ]]; then
    echo -e " "
    echo -e "No Database available to backup." 
    continue
  else
    if [[ ! -d ${BACKUPDIR}/${CTNAME[$i]} ]]; then mkdir -p "${BACKUPDIR}/${CTNAME[$i]}"; fi
    cd ${BACKUPDIR}/${CTNAME[$i]}/
    for ((j = 0; j < ${#DBNAME[@]}; ++j)); do
      if [[ "$NEWER_DB_ONLY" = "1" ]]; then
        if [[ -s ${BACKUPDIR}/${CTNAME[$i]}/${DBNAME[$j]} ]]; then 
          continue
        fi
      fi
      echo -en "Backup database ${DBNAME[$j]}: "
      (curl --silent --show-error --fail \
        -X POST \
        -F "master_pwd=$1" \
        -F "name=${DBNAME[$j]}" \
        -F 'backup_format=zip' \
        -o ${DBNAME[$j]}.zip \
        http://${CT_IP}:8069/web/database/backup) &
      wait $!
      ret=$?
      if [[ "$ret" -eq "0" ]]; then
        echo -e '\E[38;5;10m'"DONE \e[00m"
      else
        echo -e '\E[38;5;196m'"ERROR exit code: $ret \e[00m"
      fi
    done
  fi
  echo -e '\E[38;5;10m'"$LINE_E \e[00m"
  echo ""
done
