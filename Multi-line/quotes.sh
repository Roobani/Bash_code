#!/bin/bash

# string in single line

echo 'Hello Rooban'
# Srting in double line
echo "We are javapoint"
echo
echo
#..............................
#quotes with variabale
name="You are welcome to at Sodexis"
echo "$name"
echo '$name'
echo
echo
echo
#.............................

#quotes with mulyiple variable and string

echo "When single quotes used with string"
invitation='welcome to Sodexis'
echo $invitation 
echo
echo "when double quotes used with string"
invitation="wlecome to Sodexis"
echo $invitation
echo
echo "when variable is used with double quote"
Remark="Hello user, $invitation"
echo $Remark
echo
echo "when variable is used with single quote"
Remark='Hello user, $invitation'
echo $Remark
echo

