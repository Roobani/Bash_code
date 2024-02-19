#!/bin/bash
cd /home/john/Desktop
filename=user.log
if [ ! -f "$filename" ]
then
   echo "File "$filename" does not exit"
else
   echo "File "$filename" exits"
fi
