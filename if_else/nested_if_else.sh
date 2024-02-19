#! /bin/bash

read -p "Enter  the value: " value
if [ $value -gt 10 ];
then
 if [ $value -lt 20 ];
 then
   echo "$value>10,$value<20"
 else
  echo "The value you typed is greater than 10"
 fi
else echo "The value you typed is not greater than 20"
fi
