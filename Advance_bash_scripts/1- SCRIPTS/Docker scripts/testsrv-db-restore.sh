#!/bin/bash
BACKUPDIR="/Backup/2019-01-02_02\:43\:42"
CREDENTIALS_FILE="db-credentials.txt"

while IFS='' read -r line || [[ -n "$line" ]]; do
  N=$((N+1))
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
    declare -a "$line"
done < "${CREDENTIALS_FILE}"

LINE_E=$(printf -v sep '%*s' 50 ; echo "${sep// /=}")

if [[ -z "$BACKUPDIR" ]]; then echo BACKUPDIR is empty; exit 1; fi

for ((i = 1; i <= N; i++)); do
  #Check for commented server.
  TMP_CT=C${i}
  CT=("${!TMP_CT}")
  if [ ! -z "${CT}" ]; then
    TMP_AR="C$i[@]"
    AR=("${!TMP_AR}")
    if [ "${#AR[@]}" -ne "2" ]; then
      echo "Skipping the container "$TMP_CT". An error found in values"
      continue
    fi
    echo -e '\E[38;5;10m'"$LINE_E \e[00m"
    echo -e '\E[38;5;10m'"Restoring Database for ${AR[0]}:\e[00m"
    CT_IP="$(docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${AR[0]})"
    for file in ${BACKUPDIR}/${AR[0]}/*; do
      name=${file##*/}
      base=${name%.zip}
      echo -en "Restoring database ${base}: "
      (curl --silent --show-error --fail \
            -F "master_pwd=${AR[1]}" \
            -F "backup_file=@${BACKUPDIR}/${AR[0]}/${name}" \
            -F 'copy=true' \
            -F "name=${base}" \
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
  fi
done
