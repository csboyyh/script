#!/bin/bash

Date=`date +%m%d%y`

Server="chjandroid01 chjandroid02 chjandroid03"

for Server in $Server

do

Quota=`/bin/cat /log/$Server/quota.log | grep + | head -n 1 | awk -F[:" "]+ '{print $9}'`

#if [ $Ping -eq "0" ]
#then
#echo "$Server is ok"  >> /log/Ping/$Date.log
#elif [ $Ping2 -eq "100" ]
if [ $Quota = "0" ]
then
/usr/bin/mail -s "$Server Over quota" zhiming.yang@spreadtrum.com < /log/$Server/quota.log
fi
done
