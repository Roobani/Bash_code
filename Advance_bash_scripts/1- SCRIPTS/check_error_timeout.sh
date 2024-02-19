#!/bin/bash
# Script that checks for occurrence of worker timeout message and email it
SCRIPT_NAME=`basename $0`
HOST=`hostname`
MAIL="$(which mail)"
OPENERP_lOG=/var/log/openerp/openerp-sciencefirst.log
A_EMAIL=skeller@sodexis.com
CC1=john@sodexis.com
CHECK_CONTEXT=timeout
TMP_LOG=/opt/scripts/logs/"${SCRIPT_NAME}".log
TIME_AGO="5 min ago"
CHECKCOUNT=$(awk -v d1="$(date +'%F %H:%M:%S' -ud "$TIME_AGO")" -v d2="$(date +'%F %H:%M:%S' -u)" '$0 > d1 && $0 < d2 || $0 ~ d2' $OPENERP_lOG | grep -c "$CHECK_CONTEXT")
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
    echo -e "$CHECKCOUNT occurrences of the $CHECK_CONTEXT has been found past "$TIME_AGO" in openerp-server.log of "$HOST".\nThe log file of past "$TIME_AGO" is attached in this email.\n\n------------------------------\n"$SCRIPT_NAME"" | $MAIL -a "$TMP_LOG" -s "$CHECK_CONTEXT FOUND [$CHECKCOUNT] - $HOST" -- $A_EMAIL $CC1 $CC2
else
    echo "Do nothing" > /dev/null
fi
