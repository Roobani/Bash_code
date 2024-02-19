#!/bin/sh
BACKUP=/backup/sugarcrm
WEBDIR=/var/www/vhosts/sodexis.com/subdomains/databases/httpsdocs/data/matthews/SugarCRM
[ ! -d $WEBDIR ] && mkdir -p $WEBDIR || :
rm -rf $WEBDIR/*.*
cp -R $BACKUP/*.* $WEBDIR
exit 0
