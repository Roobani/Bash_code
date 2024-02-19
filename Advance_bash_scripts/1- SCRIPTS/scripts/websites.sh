#!/bin/bash
GZIP="$(which gzip)"
NOW=$(date +"%d-%m-%Y")
rm -rf /var/app/*.tar.bz2
rm -rf /var/app/oracle/*.tar.bz2
rm -rf /var/www/vhosts/*.tar.bz2
tar -jcvf /var/app/compiere-$NOW.tar.bz2 /var/app/compiere --exclude='/var/app/compiere/blueprint/blueprintsvn' --exclude='/var/app/compiere/*.tar.bz2'
tar -jcvf /var/app/oracle/fast_recovery_area-$NOW.tar.bz2 /var/app/oracle/fast_recovery_area --exclude='/var/app/oracle/*.tar.bz2'
tar -jcvf /var/www/vhosts/globalfoodinternational-$NOW.tar.bz2 /var/www/vhosts/globalfoodinternational.com --exclude='/var/www/vhosts/*.tar.gz'
tar -jcvf /var/www/vhosts/myvirtualprogrammer-$NOW.tar.bz2 /var/www/vhosts/myvirtualprogrammer.com --exclude='/var/www/vhosts/*.tar.gz'
tar -jcvf /var/www/vhosts/sodexis.com-$NOW.tar.bz2 /var/www/vhosts/sodexis.com --exclude='/var/www/vhosts/sodexis.com/subdomains/test' --exclude='/var/www/vhosts/*.tar.gz'
tar -jcvf /var/www/vhosts/sodexis.net-$NOW.tar.bz2 /var/www/vhosts/sodexis.net --exclude='/var/www/vhosts/*.tar.gz'
exit 0
