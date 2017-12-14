#!/bin/bash 

file=.tmp.serverlload

for ((i=11;i<=15;i++));
do 
    ssh heyang@shanN$i uptime 2>&1 | grep "load average" | sed "s/^/shanN$i /" | tee $file.shanN$i  & 
done

sleep 2 

server=`cat $file.shanN*  | sort  -g  -k 13 |  head -n1 | awk '{print $1}'`
echo ">>>>> now go server: $server"

ssh heyang@$server

