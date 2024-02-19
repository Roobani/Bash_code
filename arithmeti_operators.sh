#!/bin/bash
echo
sum=$((10+3))
echo "sum=$sum"
echo
((sum=10+3))
echo "sum=$sum"
echo
n1=10
n2=3
((sum=n1+n2))
echo "sum=$sum"
echo
n1=10
n2=3
sum=$((n1+n2))
echo "sum=$sum"
echo


echo "********************* testing ******************************"
x=8  
y=2  
echo "x=8, y=2"  
echo "Addition of x & y"  
echo $(( $x + $y ))  
echo "Subtraction of x & y"  
echo $(( $x - $y ))  
echo "Multiplication of x & y"  
echo $(( $x * $y ))  
echo "Division of x by y"  
echo $(( $x / $y ))  
echo "Exponentiation of x,y"  
echo $(( $x ** $y ))  
echo "Modular Division of x,y"  
echo $(( $x % $y ))  
echo "Incrementing x by 5, then x= "  
(( x += 5 ))   
echo $x  
echo "Decrementing x by 5, then x= "  
(( x -= 5 ))  
echo $x  
echo "Multiply of x by 5, then x="  
(( x *= 5 ))  
echo $x  
echo "Dividing x by 5, x= "  
(( x /= 5 ))  
echo $x  
echo "Remainder of Dividing x by 5, x="  
(( x %= 5 ))  
echo $x  
