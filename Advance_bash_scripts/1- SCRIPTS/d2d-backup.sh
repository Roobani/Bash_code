#!/bin/sh
# $Id: d2d-backup.sh,v 1.1 2004/08/05 22:00:02 tomh Exp $

# Do incremental backups to a second filesystem.
# Full backups are done on Sunday, incrementals since then.

# This is expected to be its own filesystem
backup_location="/backup"
sql_dir="$backup_location/sql"
day=`date +%w`
date=`date +%d-%m-%Y`
[ -f "/etc/mysqlpswd" ] && sql_pass=`cat /etc/mysqlpswd`
mysqldump="/usr/local/mysql/bin/mysqldump"
mysql="/usr/local/mysql/bin/mysql"

# Be sane
umask 077

# Tar all filesystems.
# (Preferred over dump here since the filesystems will be read/write)

filesystems=`awk '/ext[23]/ {print $2}' /etc/fstab | grep -v $backup_location`

for fs in $filesystems
do
	basename=`echo $fs | sed -e 's/\///g'`
	[ -z "$basename" ] && basename=root

	if [ "$day" = 0 -o ! -f "$backup_location/$basename.full.tar.gz" ]
	then
		file="$backup_location/$basename.full.tar.gz"

		tar clzf $file $fs
	else
		file="$backup_location/$basename.$date.tar.gz"
		filelist="$backup_location/$basename.changed"

		find $fs -xdev -mtime -1 -type f -print > $filelist

		[ -s $filelist ] && tar clzfT $file $filelist

		rm $filelist
	fi
done

# Handle MySQL databases
if [ -n "$sql_pass" ]
then
	databases=`$mysql -p$sql_pass -B -N -e 'show databases'`
else
	echo "Could not determine password.  SQL dumps skipped."
fi

if [ -n "$databases" ]
then
	[ ! -d "$sql_dir" ] && mkdir -m 700 $sql_dir

	for db in $databases
	do
		file="$sql_dir/$db.sql.gz"
		$mysqldump -q -p$sql_pass $db | gzip > $file
	done
fi

# clean up
find $backup_location -mtime +14 -type f -exec rm {} \;
