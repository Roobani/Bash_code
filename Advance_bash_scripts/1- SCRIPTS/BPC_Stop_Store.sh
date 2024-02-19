#!/bin/bash

#Script to stop BPC store every Monday & Thurday at 1 AM Est and start at 4 AM EST.
#Author: JOHN (Sodexis admin).

DIRECTORY=/var/www/vhosts/blueprintcleanse.com/subdomains/store/httpsdocs/
FILE=index.html
ALERT_MAIL=john@sodexis.com
CC1=dailymonitoring@sodexis.com 
CC2=v.s.elangovan@sodexis.com
DAY=$(date '+%A')

cd $DIRECTORY
if [ -f $FILE ]; then
	cp index.html index.html_save
fi	
			
if fgrep -n -e '<link type="text/css" rel="stylesheet" href="https://store.blueprintcleanse.com/gwtstore/downpanel.css">' -e '<script type="text/javascript" language="javascript" src="https://store.blueprintcleanse.com/gwtstore/gwtstore.nocache.js">' index.html; then
		
	sed -i -e 's_"https://store.blueprintcleanse.com/gwtstore/downpanel.css"_"https://sstore.blueprintcleanse.com/gwtstore/downpanel.css"_g' index.html
	sed -i -e 's_"https://store.blueprintcleanse.com/gwtstore/gwtstore.nocache.js"_"https://sstore.blueprintcleanse.com/gwtstore/gwtstore.nocache.js"_g' index.html
	echo "Hostname: $(hostname)" > out.txt
	echo " " >> out.txt
	echo "Day: $(date '+%A')" >> out.txt
	echo " " >> out.txt 
	echo "Comment: Automated script made BPC shopping cart OFFLINE at 1:00 AM EST. It will become ONLINE at 4:00 AM EST." >> out.txt
	echo " " >> out.txt
	if fgrep -n -e '<link type="text/css" rel="stylesheet" href="https://sstore.blueprintcleanse.com/gwtstore/downpanel.css">' -e '<script type="text/javascript" language="javascript" src="https://sstore.blueprintcleanse.com/gwtstore/gwtstore.nocache.js">' index.html >> out.txt; then
		mail -s "BPC Store is OFFLINE" -c $CC1 -c $CC2 $ALERT_MAIL < out.txt
		rm -rf out.txt
	else
		echo "Failed to stop the BPC store!" | mail -s "ALERT - BPC_Stop_store script failed" $ALERT_MAIL
	exit 1
	fi
else
	sed -i -e 's_"https://sstore.blueprintcleanse.com/gwtstore/downpanel.css"_"https://store.blueprintcleanse.com/gwtstore/downpanel.css"_g' index.html
	sed -i -e 's_"https://sstore.blueprintcleanse.com/gwtstore/gwtstore.nocache.js"_"https://store.blueprintcleanse.com/gwtstore/gwtstore.nocache.js"_g' index.html
	echo "Hostname: $(hostname)" > out.txt
	echo " " >> out.txt
	echo "Day: $(date '+%A')" >> out.txt
        echo " " >> out.txt
	echo "Comment: Automated script made BPC shopping cart ONLINE at 4:00 AM EST." >> out.txt
        echo " " >> out.txt
	if fgrep -n -e '<link type="text/css" rel="stylesheet" href="https://store.blueprintcleanse.com/gwtstore/downpanel.css">' -e '<script type="text/javascript" language="javascript" src="https://store.blueprintcleanse.com/gwtstore/gwtstore.nocache.js">' index.html >> out.txt; then
		mail -s "BPC Store is ONLINE" -c $CC1 -c $CC2 $ALERT_MAIL < out.txt
		rm -rf out.txt
	else
		echo "Failed to start the BPC store!" | mail -s "ALERT - BPC_Stop_store script failed" $ALERT_MAIL
	exit 1
	fi
fi
exit 0