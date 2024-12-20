#!/bin/bash
echo " EXAMPLE 1 "
echo
d=`date +%m-%d-%Y`
echo "Date in format MM-DD-YYYY"
echo $d #MM-DD-YYYY
echo

echo " EXAMPLE 2 "
d=`date +%m-%Y`
echo "Date in format MM-YYYY"
echo $d #MM-YYYY
echo


echo " EXAMPLE 3: Weekday DD-Month-YYYY"
d1=`date '+%A %d-%m-%Y'`
d2=`date '+%a %d-%m-%Y'`
echo "Date in format weekday DD-Month,YYYY"
echo $d1
echo $d2
echo

echo "EXAMPLE 4: MONTH SHORT FORM"
m1=`date '+%B %d-%Y'`
m2=`date '+%b %d-%Y'`
echo "Date in format Month DD-YYYY"
echo $m1
echo $m2
echo

echo "EXAMPLE 5: CURRENT DATE IN MM/DD/YY"
d=`date +%D`
echo $d
echo

echo "EXAMPLE 6: CUREENT DATE SHOWN IN YYYY-MM-DD"
d=`date +%F`
echo $d
echo

echo "EXAMPLE 7: HOURS SHOWN IN 24-hrs CLOCK FORMAT"
d=`date +%H`
echo $d
echo

echo "EXAMPLE 8: TIME ZONE ABBREVIATION:"
d=`date +%Z`
echo $d
echo
