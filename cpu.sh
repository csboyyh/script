#!/bin/bash

Name=`hostname`

IP=`/sbin/ifconfig em1 | grep "inet addr" | awk -F[:" "]+ '{print $4}'`

Date=`date +%m%d%y`

Num=`/usr/sbin/dmidecode | grep -i 'serial number' | head -n 1`

CPU=`/sbin/hpasmcli -s "show server" | grep Status | awk -F[:" "]+ '{print $2}'`
CPU2=`/sbin/hpasmcli -s "show server" | grep Speed | awk -F[:" "]+ '{print $2}' | head -n 1`MHz
CPU3=`/sbin/hpasmcli -s "show server" | grep Core | awk -F[:" "]+ '{print $2}' | head -n 1`core

touch /log/$Date.log

i=1

for OK in $CPU
  do
    if [ $OK = "Ok" ]
then
echo "$Name($IP) $i cpu($CPU2,$CPU3) is OK"  >> /log/$Date.log
     i=$(( $i + 1 ))
else
echo "$Name($IP) $i cpu($CPU2,$CPU3) is bad"  >> /log/$Date.log
echo "$Num" >> /log/$Date.log
 i=$(( $i + 1 ))
  fi
done
/bin/sh /usr/local/bin/power.sh
