#!/bin/bash
#domain cleanup.

DOMAIN_NAME=$1

if [[ -z "$1" ]]; then echo "This script require domain name as argument"; exit 1; fi

if ls /usr/local/nginx/conf/conf.d/${DOMAIN_NAME}.* > /dev/null 2>&1; then
  rm -rfv /usr/local/nginx/conf/conf.d/${DOMAIN_NAME}.*
else
  echo "The $DOMAIN_NAME configurations not found. Check name"
  exit 1
fi

if [[ -d /usr/local/nginx/conf/ssl/${DOMAIN_NAME} ]]; then
  rm -rfv /usr/local/nginx/conf/ssl/${DOMAIN_NAME}
fi

if [[ -d /usr/local/nginx/conf/ssl/cloudflare/${DOMAIN_NAME} ]]; then
  rm -rfv /usr/local/nginx/conf/ssl/cloudflare/${DOMAIN_NAME}
fi

if [[ -d /home/nginx/domains/${DOMAIN_NAME} ]]; then
  rm -rfv /home/nginx/domains/${DOMAIN_NAME}
fi

if ls /usr/local/nginx/conf/pre-staticfiles-local-${DOMAIN_NAME}.* > /dev/null 2>&1; then
  rm -rfv /usr/local/nginx/conf/pre-staticfiles-local-${DOMAIN_NAME}.*
fi

if [[ -d /root/.acme.sh/${DOMAIN_NAME} ]]; then
  rm -rfv /root/.acme.sh/${DOMAIN_NAME}
fi

for D1 in /home/acmesh-backups/${DOMAIN_NAME}-*; do
  if [ -d $D1 ]; then
    rm -rfv /home/acmesh-backups/${DOMAIN_NAME}-*
  fi
done

if ls /usr/local/nginx/conf/acmevhostbackup/${DOMAIN_NAME}.* > /dev/null 2>&1; then
  rm -rfv /usr/local/nginx/conf/acmevhostbackup/${DOMAIN_NAME}.*
fi

if ls /usr/local/nginx/conf/acmevhostbackup/${DOMAIN_NAME}.* > /dev/null 2>&1; then
  rm -rfv /usr/local/nginx/conf/acmevhostbackup/${DOMAIN_NAME}.*
fi

if [[ -d /usr/local/nginx/conf/autoprotect/${DOMAIN_NAME} ]]; then
  rm -rfv /usr/local/nginx/conf/autoprotect/${DOMAIN_NAME}
fi

if ls /root/centminlogs/*${DOMAIN_NAME}.log > /dev/null 2>&1; then
  rm -rfv /root/centminlogs/*${DOMAIN_NAME}.log
fi

systemctl restart nginx