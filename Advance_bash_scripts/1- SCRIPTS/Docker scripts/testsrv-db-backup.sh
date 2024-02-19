#1/bin/bash
BACKUPDIR="/Backup/$(date +%F_%T)"
CREDENTIALS_FILE="db-credentials.txt"

while IFS='' read -r line || [[ -n "$line" ]]; do
  N=$((N+1))
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
    declare -a "$line"
done < "${CREDENTIALS_FILE}"

LINE_E=$(printf -v sep '%*s' 50 ; echo "${sep// /=}")

if [ ! -d "$BACKUPDIR" ]; then mkdir -p $BACKUPDIR; fi

for ((i = 1; i <= N; i++)); do
  #check for empty array due to comment.
  TMP_CT=C${i}
  CT=("${!TMP_CT}")
  if [ ! -z "${CT}" ]; then
    TMP_CT=C${i}
    CT=("${!TMP_CT}")
    TMP_AR="C$i[@]"
    AR=("${!TMP_AR}")
    if [ "${#AR[@]}" -ne "2" ]; then
      echo "Skipping the container "$TMP_CT". An error found in values"
      continue
    fi
    echo -e '\E[38;5;10m'"$LINE_E \e[00m"
    echo -e '\E[38;5;10m'"Backup Database for ${AR[0]}:\e[00m"
    CONFIG="/opt/odoo/${AR[0]}/conf/odoo.conf"
    CT_IP="$(docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${AR[0]})"
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
      mkdir -p "${BACKUPDIR}/${AR[0]}"
      cd ${BACKUPDIR}/${AR[0]}/
      for ((j = 0; j < ${#DBNAME[@]}; ++j)); do
        echo -en "Backup database ${DBNAME[$j]}: "
        (curl --silent --show-error --fail \
              -X POST \
              -F "master_pwd=${AR[1]}" \
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
  fi
done
