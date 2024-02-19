#!/bin/bash
#Script to backup gitlab server. (omnibus installation)
#Author: John Britto (system admin, Sodexis)
#Date: 14/12/2015
#============================================================================================
# Restore: untar the package of git-config-(date).tar.gz in /etc/gitlab. It consist of .json file needed for  two-factor authentication (2FA)
# , gitlab.rb (gitlab settings) and iptables.conf to resotre the iptables using iptables-restore < iptables.conf
# Restore command for gitlab backup tar: (check for update info)
# Stop processes that are connected to the database

# sudo gitlab-ctl stop unicorn
# sudo gitlab-ctl stop sidekiq

# This command will overwrite the contents of your GitLab database!

# sudo gitlab-rake gitlab:backup:restore BACKUP=1393513186

# Start GitLab
#sudo gitlab-ctl start

# Check GitLab
# sudo gitlab-rake gitlab:check SANITIZE=true

#If there is a GitLab version mismatch between your backup tar file and the installed version of GitLab, the restore command will abort with an error. Install a package for the required version and try again.
#============================================================================================
#Fix no entry for terminal type "unknown"; using dumb terminal settings error
export TERM=dumb

HOST="$(echo $HOSTNAME)"
SCRIPT_NAME=`basename $0`
BACKUPDIR="/mnt/nfs-backup/gitlab"
GITLAB_CONFIG_BASE="/etc/gitlab"
TR="$(which tree)"
GIT_RAKE="$(which gitlab-rake)"
IPTABLES_SAVE="/sbin/iptables-save"
LOGDIR="/opt/scripts/logs"
LOGFILE=${LOGDIR}/${SCRIPT_NAME}-`date +%N`.log
LOGERR=${LOGDIR}/${SCRIPT_NAME}-ERRORS-`date +%N`.log
MAILADDR="dailymonitoring@sodexis.com"
REPLYTO="john@sodexis.com"
# IO redirection for logging.
if [ -d "$LOGDIR" ]; then
  mkdir -p $LOGDIR
fi
touch $LOGFILE
exec 6>&1
exec > $LOGFILE
touch $LOGERR
exec 7>&2
exec 2> $LOGERR
#Check for Mount directory /mnt/nfs-backup/gitlab is mounted or not, if not mounted try to mount it.
if ! mountpoint -q "$BACKUPDIR"; then
echo ERROR: $BACKUPDIR was not mounted. | mail -s "ERRORS - GITLAB Backup for $HOST" -Sreplyto="$REPLYTO" -b "$BCC" "$MAILADDR"
exit 1
fi

if [ ! -d "$BACKUPDIR"/gitlab-config ]; then
	mkdir -p ${BACKUPDIR}/gitlab-config
fi
echo
echo -e $(yes '=' | head -50 | paste -s -d '' -)
echo GITLAB SERVER INFO
echo -e $(yes '=' | head -50 | paste -s -d '' -)
sudo $GIT_RAKE gitlab:env:info
echo
echo -e $(yes '=' | head -50 | paste -s -d '' -)
echo "GITLAB CONFIG BACKUP [/etc/gitlab/*]"
echo -e $(yes '=' | head -50 | paste -s -d '' -)
$IPTABLES_SAVE > ${GITLAB_CONFIG_BASE}/iptables.conf
echo Rotating 1 week backup...
REMW="(date '+%Y-%m-%d' -d '1 week ago')"
if [ -f "${BACKUPDIR}/gitlab-config/gitlab-config-${REMW}.*" ]; then
  eval rm -fv "${BACKUPDIR}/gitlab-config/gitlab-config-${REMW}.*"
fi
#Cleaning if by any case 2 month ago backup were missed to get cleaned.
find "${BACKUPDIR}/gitlab-config/" -type f -mtime +8 -exec rm -f {} +
echo
/bin/tar -cvzPf ${BACKUPDIR}/gitlab-config/gitlab-config-$(date +%Y-%m-%d).tar.gz ${GITLAB_CONFIG_BASE}/
echo
echo -e $(yes '=' | head -50 | paste -s -d '' -)
echo "GITLAB REPOSITORY BACKUP"
echo -e $(yes '=' | head -50 | paste -s -d '' -)

sudo $GIT_RAKE gitlab:backup:create
echo -e $(yes '=' | head -50 | paste -s -d '' -)
echo
echo "Backup Stored in $BACKUPDIR"
echo
$TR -Dh $BACKUPDIR

#Clean up IO redirection
exec 1>&6 6>&-      # Restore stdout and close file descriptor #6.
exec 1>&7 7>&-      # Restore stdout and close file descriptor #7.

# -s means file is not zero size
if [ -s "$LOGERR" -a -s "$LOGFILE" ]; then
    cat "$LOGERR" | mail -s "ERRORS - GITLAB Backup for $HOST" -Sreplyto="$REPLYTO" "$MAILADDR"
    cat "$LOGFILE" | mail -s "SUCCESS - GITLAB Backup for $HOST" -Sreplyto="$REPLYTO" "$MAILADDR"
elif [ -s "$LOGERR" -a ! -s "$LOGFILE" ]; then
    cat "$LOGERR" | mail -s "ERRORS - GITLAB Backup for $HOST" -Sreplyto="$REPLYTO" "$MAILADDR"
else
    cat "$LOGFILE" | mail -s "SUCCESS - GITLAB Backup for $HOST" -Sreplyto="$REPLYTO" "$MAILADDR"
fi

if [ -s "$LOGERR" ]; then
    STATUS=1
else
    STATUS=0
fi
# Clean up Logfile
find "$LOGDIR"/git*.log -type f -mtime +3 -exec rm -f {} +
exit $STATUS
