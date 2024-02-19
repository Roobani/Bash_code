#!/bin/bash
#when the condition is true
if [ 10 -gt 3 ];
then
  echo "10 is greater than 3."
else
  echo "10 is not greater than 3."
fi
#when the condition is false
if [ 3 -gt 10 ];
then
  echo "3 is greater than 10."
else
  echo "3 is not greater than 10."
fi
