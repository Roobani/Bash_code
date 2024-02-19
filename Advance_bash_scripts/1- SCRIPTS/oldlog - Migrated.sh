#!/bin/bash
#
# Make sure that the keybased athentication created from Root user to all the server. and the .pub key transfered to them for 
# successfully login.
#
SCRIPT_NAME=`basename $0`
LOGDIR="/opt/support_files/scripts/logs"
LOGFILE=$LOGDIR/$SCRIPT_NAME-`date +%m_%d-%H:%M:%S`.log
LOGERR=$LOGDIR/$SCRIPT_NAME-ERRORS-`date +%m_%d-%H:%M:%S`.log

MAILADDR="dailymonitoring@sodexis.com"
CC1="john@sodexis.com"

# IO redirection for logging.
touch $LOGFILE
exec 6>&1           # Link file descriptor #6 with stdout.
                    # Saves stdout.
exec > $LOGFILE     # stdout replaced with file $LOGFILE.
touch $LOGERR
exec 7>&2           # Link file descriptor #7 with stderr.
                    # Saves stderr.
exec 2> $LOGERR     # stderr replaced with file $LOGERR.

odoopro () {
	VM_USER=sodexis
	VM_ADDR=proserv.sodexis.com
	ODOO_12_LOG_SOURCE=/opt/odoo-12/logs/
	ODOO_12_LOG_DEST=/data/oldlogs/Sodexis/Odoo-12/
	echo
	echo "Syncing Odoo 12 Pro logs:-"
    echo ================================================================
	rsync -av -e "ssh -p 4011" --delete-before "$VM_USER"@"$VM_ADDR":"$ODOO_12_LOG_SOURCE" "$ODOO_12_LOG_DEST"
	echo ================================================================
	echo
	echo
}

sohpro () {
    USER=sodexis
    SOH_ADDR=proserv.sodexis.com
    SOH_LOG_SOURCE=/opt/odoo-12/logs/
	SOH_LOG_DEST=/data/oldlogs/Sohre/Odoo-12
    echo "Syncing SOHRE Odoo logs:-"
    echo ================================================================
    rsync -av -e "ssh -p 4013" --delete-before "$USER"@"$SOH_ADDR":"$SOH_LOG_SOURCE" "$SOH_LOG_DEST"
    echo ================================================================
    echo
    echo
}

lspro () {
    USER=sodexis
    LS_ADDR=proserv.sodexis.com
    LS10_LOG_SOURCE=/var/log/odoo-10/
	LS10_LOG_DEST=/data/oldlogs/LabSociety/Odoo-10/
    LS12_LOG_SOURCE=/opt/odoo-12/logs/
    LS12_LOG_DEST=/data/oldlogs/LabSociety/Odoo-12/
    echo "Syncing LS Odoo-10 logs:-"
    echo ================================================================
    rsync -av -e "ssh -p 4015" --delete-before "$USER"@"$LS_ADDR":"$LS10_LOG_SOURCE" "$LS10_LOG_DEST"
    echo ================================================================
    echo
    echo "Syncing LS Odoo-12 logs:-"
    echo ================================================================
    rsync -av -e "ssh -p 4015" --delete-before "$USER"@"$LS_ADDR":"$LS12_LOG_SOURCE" "$LS12_LOG_DEST"
    echo ================================================================
    echo
    echo
}

laspro () {
    USER=sodexis
    LAS_ADDR=proserv.sodexis.com
    LAS_LOG_SOURCE=/opt/odoo-11/logs/
    LAS_LOG_DEST=/data/oldlogs/LaSiesta/Odoo-11/
    echo "Syncing LaSiesta Odoo logs:-"
    echo ================================================================
    rsync -av -e "ssh -p 4018" --delete-before "$USER"@"$LAS_ADDR":"$LAS_LOG_SOURCE" "$LAS_LOG_DEST"
    echo ================================================================
    echo
    echo
}

henpro () {
    USER=sodexis
    HEN_ADDR=proserv.sodexis.com
    HEN_LOG_SOURCE=/opt/odoo-12/logs/
    HEN_LOG_DEST=/data/oldlogs/Hennepen/Odoo-12/
    echo "Syncing Hennepens Odoo logs:-"
    echo ================================================================
    rsync -av -e "ssh -p 4010" --delete-before "$USER"@"$HEN_ADDR":"$HEN_LOG_SOURCE" "$HEN_LOG_DEST"
    echo ================================================================
    echo
    echo
}

nccpro () {
    USER=sodexis
    NCC_ADDR=68.233.218.190
    NCC_LOG_SOURCE=/opt/odoo-12/logs/
    NCC_LOG_DEST=/data/oldlogs/NCCRC/Odoo-12/
    echo "Syncing NCCRC Odoo logs:-"
    echo ================================================================
    rsync -av -e "ssh -p 2295" --delete-before "$USER"@"$NCC_ADDR":"$NCC_LOG_SOURCE" "$NCC_LOG_DEST"
    echo ================================================================
    echo
    echo
}

kgpro () {
    USER=sodexis
    KG_ADDR=proserv.sodexis.com
    KG_LOG_SOURCE=/opt/odoo-12/logs/
    KG_LOG_DEST=/data/oldlogs/Kiosk/Odoo-12/
    echo "Syncing Kiosk Odoo logs:-"
    echo ================================================================
    rsync -av -e "ssh -p 4017" --delete-before "$USER"@"$KG_ADDR":"$KG_LOG_SOURCE" "$KG_LOG_DEST"
    echo ================================================================
    echo
    echo
}


odoopro
sleep 5
sohpro
sleep 5
lspro
sleep 5
laspro
sleep 5
henpro
sleep 5
nccpro
sleep 5
kgpro
sleep 5

#Clean up IO redirection
exec 1>&6 6>&-      # Restore stdout and close file descriptor #6.
exec 1>&7 7>&-      # Restore stdout and close file descriptor #7.
if [ -s "$LOGERR" -a -s "$LOGFILE" ]; then
    cat -v "$LOGERR" | mail -s "ERRORS - Oldlog sync" $MAILADDR $CC1
    cat -v "$LOGFILE" | mail -s "SUCCESS - Oldlog sync" $MAILADDR $CC1
elif [ -s "$LOGERR" -a ! -s "$LOGFILE" ]; then
    cat -v "$LOGERR" | mail -s "ERRORS - Oldlog sync" $MAILADDR $CC1
else
    cat -v "$LOGFILE" | mail -s "SUCCESS - Oldlog sync" $MAILADDR $CC1
fi
if [ -s "$LOGERR" ]; then
    STATUS=1
else
    STATUS=0
fi
# Clean up Logfile
find "$LOGDIR"/${SCRIPT_NAME}*.log -type f -mtime +3 -exec rm -f {} +
exit $STATUS