#!/bin/bash
IFS=$(echo -en "\n") 
awk -f ~/project/script/awk_time.sh fail.log| while read line
do
    timestamp=`echo $line |awk -F "[:()]" '{print $3}'`
    type=`echo $line |awk -F "[:()]" '{print substr($4,0,1)}'`
    if [ $type = 'U' ];then
    grep -n $timestamp ../kernel/kernel.log | \
        awk -v ty=$type -F "[=,:]" '{print "K:"ty",line="$1,",ts-tick="$7/1000-$5",apt-ts="($9/1000-$7)/1000} '
    grep -n $timestamp main.log | \
        awk -v ty=$type -F "[,:]" '/SensorHub/{print "A:"ty",line="$1,",ts-tick="$9/1000-$7",apt-ts="($11/1000-$9)/1000} '
fi
        
done
