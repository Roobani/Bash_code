#!/bin/bash
# help: to change only one instance  ./change-postgresql-possword 1 sodtest13-postgres

MODE=$1     #  1 = New instance (require CTNAME), 2 = Change default pass postgres on all instance, 3 = set new pass on all instance.
CTNAME=$2

OLD_PASS=''
NEW_PASS=''

if [[ "$MODE" -eq "1" ]]; then
  if [[ ! -z $CTNAME ]]; then
    echo -en "${CTNAME}: "
    PGPASSWORD=postgres psql -h $CTNAME -p 5432 -U postgres -d postgres -w -c "alter user postgres with password '$NEW_PASS';"
    echo "Done"
  else
    echo "please pass postgres container name as argument"
    exit 1
  fi
elif [[ "$MODE" -eq "2" ]]; then
  if [[ ! -z $CTNAME ]]; then
    echo -en "${CTNAME}: "
    PGPASSWORD=$OLD_PASS psql -h $CTNAME -p 5432 -U postgres -d postgres -w -c "alter user postgres with password '$NEW_PASS';"
    echo "Done"
  else
    echo "please pass postgres container name as argument"
    exit 1
  fi
elif [[ "$MODE" -eq "3" ]]; then
  CTNAME+=(`docker ps -a --format "{{.Names}}" -f name=postgres`)
  for ((i = 0; i < ${#CTNAME[@]}; ++i)); do
    echo -e "${CTNAME[$i]}"
    echo =========================
    PGPASSWORD=postgres psql -h ${CTNAME[$i]} -p 5432 -U postgres -d postgres -w -c "alter user postgres with password '$NEW_PASS';"
  done
  exit 1
elif [[ "$MODE" -eq "4" ]]; then
  CTNAME+=(`docker ps -a --format "{{.Names}}" -f name=postgres`)
  for ((i = 0; i < ${#CTNAME[@]}; ++i)); do
    echo -e "${CTNAME[$i]}"
    echo =========================
    PGPASSWORD=$OLD_PASS psql -h ${CTNAME[$i]} -p 5432 -U postgres -d postgres -w -c "alter user postgres with password '$NEW_PASS';"
  done
fi
