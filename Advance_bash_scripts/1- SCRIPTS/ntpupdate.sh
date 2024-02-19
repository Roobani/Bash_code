#!/bin/bash
#
#Add crontab -e  ,  1 */12 * * * /opt/scripts/ntpupdate.sh &> /opt/scripts/logs/ntpupdate.log
#
echo Previous Hwclock: $(hwclock)
echo Previous Date: $(date)
service ntp stop
ntpd -gq
service ntp start
hwclock -w
echo New Hwclock: $(hwclock)
echo New Date: $(date)