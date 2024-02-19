#! /bin/bash

echo "***** TRUE && TRUE *****"
if [ 8 -gt 6 ] &&[ 10 -eq 10 ];
then
echo "Conditions are true."
fi

echo "**** TRUE AND FALSE *****"
if [ "mylife" == "mylife" ] && [ 3 -gt 10 ];
then
echo "Conditions are  false"
fi
 
