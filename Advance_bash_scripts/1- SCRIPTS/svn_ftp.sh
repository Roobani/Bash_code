#!/bin/bash
HOST=`hostname`
SCRIPT_NAME=`basename $0`
FTPHOST='backup329.onlinehome-server.com'
FTPUSER='bk486972881'
FTPPASS='ug54890E'
FTPFOLDER='/subversion_repos'
FILESBACKUPDIR="/opt/csvn/data/dumps"
LOGDIR="/opt/csvn/data/repositories/scripts/logs"
LOGFILE=$LOGDIR/$SCRIPT_NAME-`date +%N`.log             # Logfile Name
LOGERR=$LOGDIR/ERRORS_$SCRIPT_NAME-`date +%N`.log
MAILADDR="dailymonitoring@sodexis.com"

touch $LOGFILE
exec 6>&1           # Link file descriptor #6 with stdout.
                    # Saves stdout.
exec > $LOGFILE     # stdout replaced with file $LOGFILE.
touch $LOGERR
exec 7>&2           # Link file descriptor #7 with stderr.
                    # Saves stderr.
exec 2> $LOGERR     # stderr replaced with file $LOGERR.
echo ======================================================================
echo "FTP Backup for - $HOST"
echo
lftp -e "
open $FTPHOST
user $FTPUSER $FTPPASS  
lcd $FILESBACKUPDIR
mirror --reverse --delete-first -v $FILESBACKUPDIR $FTPFOLDER
echo
sleep 30
echo -----------------------------------------------------------
echo Stored Files in FTP are as below:
echo
ls -R $FTPFOLDER
sleep 20
echo ======================================================
echo Total FTP Disk space used for Code backup storage..
du -hs $FTPFOLDER                
echo ======================================================
bye
"    
exec 1>&6 6>&-      # Restore stdout and close file descriptor #6.
exec 1>&7 7>&-      # Restore stdout and close file descriptor #7.
if [ -s "$LOGFILE" ]; then
cat "$LOGFILE" | mail -s "SUCCESS - SVN Repository Backup to FTP for $HOST" $MAILADDR
elif [ -s "$LOGERR" ]; then
cat "$LOGERR" | mail -s "FAILURE - SVN Repository Backup to FTP for $HOST" $MAILADDR
fi
if [ -s "$LOGERR" ]
        then
                STATUS=1
        else
                STATUS=0
fi
eval rm -f "$LOGFILE"
eval rm -f "$LOGERR"
exit $STATUS