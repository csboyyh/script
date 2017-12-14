#!/bin/bash
echo "find error information and save to fail.log"
awk -F '|' '/AssertionFailedError\:/{if($3!="")print $3 "Name="FILENAME,"line="FNR}' main.log| sed -r "s/^\ [0-9]*\ event(s)? //g" > fail.log
echo "counting error number and type"
awk 'BEGIN{FS="[:.]";i=0}{{if(a[$1]==0){b[i]=$1;a[$1]=$1;i++;count[$1]++}else count[$1]++}}END{for(x in a){print "count="count[x] ",reason="a[x]}}' fail.log
