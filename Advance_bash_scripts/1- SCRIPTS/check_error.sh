#!/bin/bash
# Author: John, system admin, sodexis
#
# Script that checks for occurrence of error message and email it. This depends
# on the exclude error file.
#
# Schedule in crontab to run every 1 hours as 0 */1 * * * /opt/support_files/server-files/SF_Check_error

SCRIPT_NAME=`basename $0`
HOST="Jodee Production"
OPENERP_lOG='/var/log/odoo-10/odoo-server.log'
A_EMAIL='john@sodexis.com'
#CC1='skeller@sodexis.com xavier@sodexis.com karthik@sodexis.com ksuganthi@sodexis.com atchuthan@sodexis.com'
export REPLYTO="john@sodexis.com"
CHECK_CONTEXT=ERROR
TMP_LOG=/opt/support_files/scripts/logs/"${SCRIPT_NAME}".log
TIME_AGO="1 hour ago"
EXCLUDE_LIST=/opt/support_files/scripts/"${SCRIPT_NAME}"-exclude.txt
MAIL="$(which mutt)"


if [ ! -f "$EXCLUDE_LIST" ]; then
echo -e "Exclude file is missing\nScript is stopped in crontab. Fix the exclude file and re-enable in crontab" | $MAIL -s "$SCRIPT_NAME Missing Exclude file - $HOST" -- $A_EMAIL
crontab -l | sed "/^#.*$SCRIPT_NAME/s/^#//" | crontab -
exit 1
fi
CHECKCOUNT=$(awk -v d1="$(date +'%F %H:%M:%S' -ud "$TIME_AGO")" -v d2="$(date +'%F %H:%M:%S' -u)" '$0 > d1 && $0 < d2 || $0 ~ d2' $OPENERP_lOG | grep -v -F -f "$EXCLUDE_LIST" | grep -c "$CHECK_CONTEXT")
if [ $CHECKCOUNT -gt 0 ]; then
  if ! grep -qe "$(date +'%F %H:%M' -ud "$TIME_AGO")" $OPENERP_lOG; then
    i=1
    until `grep -qe "$(date +'%F %H:%M' -ud "$TIME_AGO + $i minute")" $OPENERP_lOG`; do
      i=$(expr $i + 1)
    done
    sed -n "/^$(date +'%F %H:%M' -ud "$TIME_AGO + $i minute")/,\$p" $OPENERP_lOG > $TMP_LOG
  else
    sed -n "/^$(date +'%F %H:%M' -ud "$TIME_AGO")/,\$p" $OPENERP_lOG > $TMP_LOG
  fi
    echo -e "$CHECKCOUNT occurrences of the $CHECK_CONTEXT has been found past "$TIME_AGO" in odoo-server.log of "$HOST".\nThe log file of past "$TIME_AGO" is attached in this email.\n\n------------------------------\n"$SCRIPT_NAME"" | $MAIL -a "$TMP_LOG" -s "$CHECK_CONTEXT FOUND [$CHECKCOUNT] - $HOST" -- $A_EMAIL $CC1
else
    echo "Do nothing" > /dev/null
fi


#exclude ERROR for print.

#sed -n -e 's/^.*ERROR //p' LS_Check_error.log

#sed -n -e 's/^.*\(ERROR \)/\1/p' LS_Check_error.log
#awk '/ERROR LS_Master werkzeug: Error on request:/,/INFO/ { if ($0 !~ /(INFO)/) { print; exit } }' < LS_Check_error.log

#prints only one occurance:
#sed -e '1,/ERROR LS_Master werkzeug: Error on request:/d' -e '/INFO/,$d' LS_Check_error.log
