#!/bin/bash

all_member=("yang.xiang" "he.yang" "hua1.li" "robin_bin.zhang" "roger.luo" "kim.yu" "long.chen" "jianlin.fu")
audio_team=("yang.xiang" "he.yang" "robin_bin.zhang" "jianlin.fu")
echo "formatting input file"
dos2unix $1
sed '/id\s/ d' -i $1
count=0
for line in `grep -vn "^SP" $1 | awk -F":" '{print $1}'`
do
    let num=$line-1-count
    let count=count+1
    echo "line:"$num
    sed "$num N;s/\n//g" -i $1
done

if [ $2"x" == "audiox" ]
then
    team_member=${audio_team[@]}
else
    team_member=${all_member[@]}
fi

reg_name=`echo ${team_member[@]}|sed 's/ /\|/g'`
echo $reg_name
all=`egrep -i $reg_name $1 |wc -l`

for i in `echo ${team_member[@]}`
do
    echo "****find out "$i" loading from "$1"****"
    part=`grep -i $i $1 |wc -l`
    let pct=part*100/all
    echo "handle "$part" of all "$all" pct:"$pct"%"
    awk -v owner=$i '
         BEGIN{sum=0;IGNORECASE=1;FS="\t"}
         {if($6==owner){product[$3]=$3;count[$3]++;sum++}}
         END{for(x in product){print "product:"x"=" count[x],"pct:"count[x]/sum*100"%","of sum",sum}}' $1
    echo "statics done"
done

