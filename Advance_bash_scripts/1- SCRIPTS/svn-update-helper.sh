#!/bin/bash
MainScript=svn-update.sh
Match="$(crontab -l | grep "$MainScript" | head -c 1)"
MAIL="$(which mailx)"
A_EMAIL=john@sodexis.com
if [ "$Match" != "#" ]; then
#Enable the crontab
#crontab -l | sed "/^#.*$MainScript/s/^#//" | crontab -
T=$(crontab -l | grep $MainScript)
cat $T | $MAIL -s "RESUME - OpenerpTest [v7.0] svn udpate" "$A_EMAIL"
fi
