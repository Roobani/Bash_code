#!/bin/bash
set -e
cd /var/www/vhosts/blueprintcleanse.com/subdomains/teststore/httpsdocs
[ -f /var/www/vhosts/blueprintcleanse.com/subdomains/teststore/httpsdocs/index.html ] && echo "File exists"
cp index.html index_save.html
perl -i -p -e 's/teststore/testsstore/ if ($. == 28 || $. == 41)' index.html
firefox http://teststore.blueprintcleanse.com& pid=$!
sleep 20
kill $pid
su - compiere -c 'set -e && cd /var/app/compiere/Compiere2/utils && ./RUN_Server2Stop.sh && sleep 20 && mv server.log server$(date +%Y-%m-%d).log && sleep 60 && ./RUN_Server2.sh > server.log'
firefox http://compiere.blueprintcleanse.com& pid=$!
sleep 20
kill $pid
cd /var/www/vhosts/blueprintcleanse.com/subdomains/teststore/httpsdocs
perl -i -p -e 's/testsstore/teststore/ if ($. == 28 || $. == 41)' index.html
firefox http://teststore.blueprintcleanse.com& pid=$!
sleep 20
kill $pid
exit

