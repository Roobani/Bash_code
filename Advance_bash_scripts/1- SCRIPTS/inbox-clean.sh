#!/bin/bash
#Script to clear /var/spool/mail/  in epubsolutions server.
#Set limit in kilobytes
LMT="100000"
#Directory to check file size greater than limit.
DIR="/var/spool/mail/"
TMP_FILE="/tmp/inbox-clean.txt"
HOST=$(hostname)
EMAIL="dailymonitoring@sodexis.com"
MAIL=$(which mail)
#
#
echo Date: $(date) > $TMP_FILE
size="$(df -h /var | awk 'NR>1 {print $5}')"
if [ "${size%?}" -ge "90" ]; then
find ${DIR} -size +${LMT}k -name "*" -exec rm -fv {} \; > $TMP_FILE
CHK="$(find ${DIR} -size +${LMT}k -name "*")"
   if [ -z "${CHK}" ]; then
      cat "$TMP_FILE" | $MAIL -s "SUCCESS - Local Inbox clean for $HOST" "$EMAIL"   
   else
      cat "$TMP_FILE" | $MAIL -s "ERROR - Local Inbox clean for $HOST" "$EMAIL"
   fi
fi