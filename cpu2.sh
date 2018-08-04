#!/bin/bash

Name=`hostname`

IP=`/sbin/ifconfig eth0 | grep "inet addr" | awk -F[:" "]+ '{print $4}'`

Date=`date +%m%d%y`

Num=`/usr/sbin/dmidecode | grep -i 'serial number' | head -n 1`

CPU=`/sbin/hpasmcli -s "show server" | grep Status | awk -F[:" "]+ '{print $2}'`
CPU2=`/sbin/hpasmcli -s "show server" | grep Speed | awk -F[:" "]+ '{print $2}'`MHz

touch /log/$Date.log

i=1

for OK in $CPU
  do
    if [ $OK = "Ok" ]
then
     i=$(( $i + 1 ))
else
echo "$Name($IP) $i cpu($CPU2) is bad"  >> /log/$Date.log
echo "$Num" >> /log/$Date.log
/usr/bin/mail -s "$Name($IP) cpu bad" zhiming.yang@spreadtrum.com < /log/$Date.log
 i=$(( $i + 1 ))
  fi
done
