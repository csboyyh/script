#!/bin/sh

hel="y h e y2"
index=1
for test in "hel hell hello"
do
    echo $test
    echo $($test)
done

temp1=`echo $hel| awk '{print $1}'`
temp2=`echo $hel| awk '{print $2}'`
temp3=`echo $hel| awk '{print $3}'`
temp4=`echo $hel| awk '{print $4}'`
if [ $temp=NUL ]
then
    echo empty
else
    echo not_empty
fi

echo 1:$temp1 2:$temp2 3:$temp3 4:$temp4 "end"
echo `echo $hel | grep $temp1*`
