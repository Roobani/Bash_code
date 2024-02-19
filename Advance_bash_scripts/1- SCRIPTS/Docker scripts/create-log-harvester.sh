#!/bin/bash
CTNAME=(`docker ps --format "{{.Names}}" -f name=-odoo`)
for ((i = 0; i < ${#CTNAME[@]}; ++i)); do
	DN=`docker exec ${CTNAME[$i]} env | grep VIRTUAL_HOST | cut -d'=' -f2`
	#Get the version inbetween = and . symbols
	ODOO_VER=`docker exec ${CTNAME[$i]} env | grep BASE_CODE_BRANCH | awk -F[=.] '{print $2}'`
	#strip the word after the delimiter -
    CT=`echo "${CTNAME[$i]}" | cut -d- -f1`
    if [ ! -f /root/.log.io/harvester-${CT}.conf -o "$1" == "create" ]; then
            eval "echo \"$(< $(dirname "$0")/create-log-harvester.tmpl)\"" > /root/.log.io/harvester-${CT}.conf
    fi
    CTE+=($CT)
done
CTE+=(log_server web_server)
# Detele the file that doesn't regex match with the CTE array element. 
ls /root/.log.io/* | grep -vE "$(IFS=\| && echo "${CTE[*]}")" | xargs -r rm

systemctl -q restart log.h