#!/bin/bash
Date=`date +%m%d%y`
Date2=`date +%m%d%y -d "5 day ago"`
/bin/cat /log/selandroid01/$Date.log >> /log/$Date.log
/bin/rm /log/selandroid01/$Date2.log
/bin/rm /log/$Date2.log
/usr/bin/mail -s "sel android server status" zhiming.yang@spreadtrum.com < /log/$Date.log
/usr/bin/mail -s "sel android server status" henry.chen@spreadtrum.com < /log/$Date.log
