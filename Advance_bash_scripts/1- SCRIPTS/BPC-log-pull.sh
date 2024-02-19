#!/bin/bash
T="/tmp/BPC_log_pull.log"
DATE="$(date)"
echo $DATE > $T
ssh -X -p 2298 compiere@74.208.147.83 'find /var/app/compiere/Compiere2/log/ -name "*.log" -mtime +183 -exec basename {} \; > /tmp/excludefile.txt && exit' >> $T 2>&1
sleep 10
echo " " >> $T
echo "copying exclude file from BPC to Sodexis server..." >> $T
scp -P 2298 compiere@74.208.147.83:/tmp/excludefile.txt /tmp/ >> $T
echo " " >> $T
echo "Transfering the logs..." >> $T
rsync -avzP -e 'ssh -p 2298' --stats --exclude-from '/tmp/excludefile.txt' --delete compiere@74.208.147.83:/var/app/compiere/Compiere2/log/*.log /var/www/vhosts/sodexis.com/log.sodexis.com/oldlogs/BPC_Production_Server/Compiere_logs/ >> $T 2>&1
echo " " >> $T
echo "SCRIPT ENDS" >>$T
mail -s "BPC_Log_pull.sh" "john@sodexis.com" < $T
exit 1
