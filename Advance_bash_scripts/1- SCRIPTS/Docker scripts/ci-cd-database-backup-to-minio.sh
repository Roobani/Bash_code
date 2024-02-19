#!/bin/bash
# Increase N as per the no. of servers defined below
N=2
# Syntax example.
# server1= ( 'name' 'Database-name' postgres-version' 'host' 'db-port' 'db-user' 'db-pass' )
#server1=( 'belowtheline' 'BTL_Master_V13' '11' 'odoo12e.crcrxh8ca8ps.us-east-1.rds.amazonaws.com' '5432' 'odoo13_beta' 'hjyT67)0HG' )
server2=( 'lasiestaG' 'LASG_Master_V14' '14' 'proserv-eu.sodexis.com' '5401' 'sodexis' '9dTG20$szx2i9Y#&2kOQ' )

if ! rclone listremotes |grep minio; then
  echo "rclone remote not found, please configure it first"
  exit 1
fi

for ((i = 1; i <= N; i++)); do
  tmp_serv=server${i}
  serv=("${!tmp_serv}")
  if [ ! -z "${serv}" ]; then
    tr_name="server$i[@]"
    ar=("${!tr_name}")
    echo "Working on ${ar[0]}"
    echo "======================="
    ver="$(echo ${ar[1]} | cut -d'V' -f2)"
    echo -n "Deleting the old database: "
    if [[ "$(rclone --retries 1 lsf minio:ci-database/${ar[0]}/${ver}.0-latest.sql.gz)" == "${ver}.0-latest.sql.gz" ]]; then
      rclone -q --retries 1 deletefile minio:ci-database/${ar[0]}/${ver}.0-latest.sql.gz > /dev/null 2>&1
      echo "DONE"
    else
      echo "NOT FOUND"
    fi
    echo -n "Dumping the database ${ar[1]}: "
    PSQL="/usr/lib/postgresql/${ar[2]}/bin/pg_dump"
    if [ ! -f "$PSQL" ]; then
      echo "ERROR. The database client version not found in the server"
    fi
    if PGPASSWORD="${ar[6]}" $PSQL -h "${ar[3]}" -p "${ar[4]}" -U "${ar[5]}" -w -O "${ar[1]}" | gzip > /tmp/${ar[1]}.sql.gz; then echo "DONE"; else echo "ERROR"; fi 
    echo -e "Transferring the dump to minio: "
    rclone copyto /tmp/${ar[1]}.sql.gz minio:ci-database/${ar[0]}/${ver}.0-latest.sql.gz
    if [[ "$(rclone --retries 1 lsf minio:ci-database/${ar[0]}/${ver}.0-latest.sql.gz)" == "${ver}.0-latest.sql.gz" ]]; then
      echo "Done"
    else
      echo "FAILED"
    fi
    rm /tmp/${ar[1]}.sql.gz
  fi
done