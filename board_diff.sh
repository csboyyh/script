#!/bin/bash

echo "Prepare to compare board:"$1" vs "$2

COMPARE_DIR="kernel,u-boot15,u-boot64,chipram,device"


tc1=`echo $1 | awk -F "[-_]" '{print NF}'`
tc2=`echo $2 | awk -F "[-_]" '{print NF}'`
count=$tc1
short=$2
long=$1
if [[ $tc1 -lt $tc2 ]];then
    count=$tc2
    short=$1
    long=$2
fi

ctyp2=`echo $long | awk -F "[-_]" '{print $1}'`
ctyp2_u=`echo $ctyp2 | tr 'a-z' 'A-Z'`

TEMP_1=~/temp/$short
TEMP_2=~/temp/$long

UPPER_1=`echo $short | tr 'a-z' 'A-Z'`
UPPER_2=`echo $long | tr 'a-z' 'A-Z'`

key_g1=`echo $short | sed 's/[-_]/\\\S\*/g'`
key_g2=`echo $long | sed 's/[-_]/\\\S\*/g'`

key_f1=`echo $short | sed 's/[-_]/\*/g'`
key_f2=`echo $long | sed 's/[-_]/\*/g'`

mkdir -p $TEMP_1 $TEMP_2

dir_count=`echo $COMPARE_DIR |awk -F "," '{print NF}'`
for ((i=1;i<=$dir_count;i++))
do
    dir=`echo $COMPARE_DIR |awk -F "," -v idx=$i '{print $idx}'`
    echo $i":Scanning directory "$dir

    for((j=1;j<=2;j++))
    do
        if [[ j -eq 1 ]];then
            ntmp=$TEMP_1
            key_f=$key_f1
            key_g=$key_g1
        else
            ntmp=$TEMP_2
            key_f=$key_f2
            key_g=$key_g2
        fi
        echo -e "\tFinding dir/file by name:"$key_f
        for d in `find $dir -name "*${key_f}*"`
        do
            echo -e "\t\tFound :"$d
            new_dir=$(dirname $d)
            mkdir -p $ntmp/$new_dir
            cp -rf $d $ntmp/$new_dir
        done
        echo -e "\tFinding dir/file by name done!"
        echo -e "\tSearching file by content:"$key_g
        for file in `egrep "$key_g" --exclude-dir=".git" -r $dir | awk -F ':' '{print $1}'|uniq`
        do
            echo -e "\t\tFound :"$file
            new_dir=$(dirname $file)
            mkdir -p $ntmp/$new_dir
            cp -f $file $ntmp/$new_dir/
        done
        echo -e "\tSearching file by content done!"
    done
    
    for ((k=1;k<=$count;k++))
    do
        token1=`echo $short | awk -v idx=$k -F "[-_]" '{print $idx}'`
        token2=`echo $long | awk -v idx=$k -F "[-_]" '{print $idx}'`
        if [[ $token1 != $token2 ]];then
            for name in `find $TEMP_2/$dir -type d -name "*$token2*"`
            do
                if [[ $token1 = "" ]];then
                    new_name=`basename $name| sed "s/[-_]$token2//g"`
                else
                    new_name=`basename $name| sed "s/$token2/$token1/g"`
                fi
                mv -f $name $(dirname $name)/$new_name
            done
            for name in `find $TEMP_2/$dir -type f -name "*$token2*"`
            do
                if [[ $token1 = "" ]];then
                    new_name=`basename $name| sed "s/[-_]$token2//g"`
                else
                    new_name=`basename $name| sed "s/$token2/$token1/g"`
                fi
                mv -f $name $(dirname $name)/$new_name
            done
            for file in `grep $token2 -ri $TEMP_2/$dir| awk -F ':' '{print $1}'|uniq`
            do
                echo -e "\tModifing:$file"
                t_u1=`echo $token1 | tr 'a-z' 'A-Z'`
                t_u2=`echo $token2 | tr 'a-z' 'A-Z'`
                if [[ $token1 = "" ]];then
                    sed -ri "/$ctyp2|$ctyp2_u/{s/\S$token2//g}" $file
                    sed -ri "/$ctyp2|$ctyp2_u/{s/\S$t_u2//g}" $file
                else
                    sed -ri "/$ctyp2|$ctyp2_u/{s/$token2/$token1/g}" $file
                    sed -ri "/$ctyp2|$ctyp2_u/{s/$t_u2/$t_u1/g}" $file
                fi
            done
        fi
    done
    diff -ru $TEMP_1/$dir $TEMP_2/$dir >~/temp/$dir.diff
done
echo "Compare finished,please search ~/temp/*.diff for detail"
