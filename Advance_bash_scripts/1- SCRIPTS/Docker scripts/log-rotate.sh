#!/bin/bash
if [ ! -d /opt/support_files/logrotate ]; then
  mkdir -p /opt/support_files/logrotate
fi
LOG_ROTATE="/opt/support_files/logrotate/odoo-logrotate"
if [ ! -f "$LOG_ROTATE" ]; then
  touch $LOG_ROTATE
  chmod 644 $LOG_ROTATE
elif [ "$1" == "create" ]; then
  > $LOG_ROTATE
else 
  > $LOG_ROTATE
fi
CTNAME=(`docker ps --format "{{.Names}}" -f name=-odoo`)
for ((i = 0; i < ${#CTNAME[@]}; ++i)); do
  #suppresses leading tabs but not spaces
cat <<- EOF >> $LOG_ROTATE
/opt/odoo/${CTNAME[$i]}/logs/odoo-server.log {
   daily
   copytruncate
   create 644 sodexis sodexis
   dateext
   dateformat -%Y-%m-%d
   rotate 15
   extension .log
}
EOF
echo " " >> $LOG_ROTATE
done
if [[ -z "$(crontab -l | grep odoo-logrotate)" ]]; then
  if [ -f /var/spool/cron/crontabs/root ]; then
    echo "" >> /var/spool/cron/crontabs/root
    echo "01 19 * * * /usr/sbin/logrotate -s /opt/support_files/logrotate/odoo-logrotate.status /opt/support_files/logrotate/odoo-logrotate" >> /var/spool/cron/crontabs/root
  fi
fi
systemctl restart cron