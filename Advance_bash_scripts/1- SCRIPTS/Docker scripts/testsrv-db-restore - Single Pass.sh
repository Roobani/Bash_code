#!/bin/bash
#Exclude servers. Add servers name seperated by space. eg: etstest11-odoo lstest10-odoo
EXCLUDE_SERVER=""
#Include servers. Add servers name seperated by space. eg: etstest11-odoo lstest10-odoo
INCLUDE_SERVER=()
#
NEWER_DB_ONLY=0        ## 0: disable, 1: enable
#
BACKUPDIR="/Backup/$(date +%F_%T)"

if [[ -z "$1" ]]; then echo "Enter the database management password as argument enclosed with single quote"; exit 1; fi

LINE_E=$(printf -v sep '%*s' 50 ; echo "${sep// /=}")

if [[ -z "$BACKUPDIR" ]]; then echo BACKUPDIR is empty; exit 1; fi

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
  echo -e '\E[38;5;10m'"Restoring Database for ${CTNAME[$i]}:\e[00m"
  CT_IP="$(docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${CTNAME[$i]})"

  for file in ${BACKUPDIR}/${CTNAME[$i]}/*; do
    NAME=${file##*/}
    BASE=${NAME%.zip}
    if [[ "$NEWER_DB_ONLY" = "1" ]]; then
      CONNECT_DB_IP=$(grep 'db_host' $CONFIG | awk '{ print $3 }')
      CONNECT_DB_PORT=$(grep 'db_port' $CONFIG | awk '{ print $3 }')
      CONNECT_DB_NAME=$(grep 'db_template' $CONFIG | awk '{ print $3 }')
      CONNECT_DB_USER=$(grep 'db_user' $CONFIG | awk '{ print $3 }')
      CONNECT_DB_PASS=$(grep 'db_password' $CONFIG | awk '{ print $3 }')
      DBNAME=(`PGPASSWORD=$CONNECT_DB_PASS psql -h $CONNECT_DB_IP -p $CONNECT_DB_PORT -d $CONNECT_DB_NAME -U $CONNECT_DB_USER -w --tuples-only -P format=unaligned -c "select datname from pg_database where datdba=(select usesysid from pg_user where usename = '${CONNECT_DB_USER}')"`);
      if [[ "${DBNAME[@]}" =~ "${BASE}" ]]; then
        continue
      fi
    fi
    echo -en "Restoring database ${BASE}: "
    (curl --silent --show-error --fail \
      -F "master_pwd=$1" \
      -F "backup_file=@${BACKUPDIR}/${CTNAME[$i]}/${NAME}" \
      -F 'copy=true' \
      -F "name=${BASE}" \
      http://${CT_IP}:8069/web/database/restore) > /dev/null 2>&1 &
    wait $!
    ret=$?
    if [[ "$ret" -eq "0" ]]; then
        echo -e '\E[38;5;10m'"DONE \e[00m"
    else
      echo -e '\E[38;5;196m'"ERROR exit code: $ret \e[00m"
    fi
  done
  echo -e '\E[38;5;10m'"$LINE_E \e[00m"
  echo ""
done
