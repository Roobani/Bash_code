#!/bin/bash

read -p "Enter a value:" value
if [ $value -gt 10 ];
then
 echo "The value typed is greater than 10";
else
 echo "The value you typed is not greater than 10";
fi
