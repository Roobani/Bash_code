#! /bin/bash

#Read user input 

echo "Enter the user name"
read first_name
echo "The current user name is $first_name " 
echo
echo "Enter the others users name"
read name1 name2 name3
echo "Those are $name1 $name2 $name3 ,other users"
echo 
echo
echo "******** USING READ COMMAND WITHOUT ANY VARIABLE *********"
echo
echo "Enter the user name"
read
echo "Name : $REPLY"
echo
