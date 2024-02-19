#! /bin/bash

echo
echo " ****** USING read COMMAND USING -p COMMAND LINE OPTIONS ******"
echo
read -p "username: " user_name
echo "the user name is " $user_name
echo
echo " ****** KEEP THE INPUT ON SILENT MODE ****** "
echo
read -p "user name: " user_name
read -sp "password: " pass_var
echo
echo "user name: " $user_name
echo "password: " $pass_var
echo
echo
echo " ****** READING MULTIPLE INPUTS USING ARRAY ****** "
echo
echo "Enter names: "
read -a names
echo "The entered names are : ${names[0]}, ${names[1]} "
echo
