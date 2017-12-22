#!/bin/bash

function usage(){
    echo -e "Script usage:\n"\
        "\t1.Support compare two boards in same branch\n" \
        "\t\tex:board_diff sp9850kh_1h10 sp9850kh_2c20\n" \
        "\t2.Support compare two boards in different branches\n" \
        "\t\tex:board_diff sp9850kh_1h10 ~/branch7.0 sp9850kh_2c20 ~/branch7.0_17e\n" \
        "\t\t(the second and firth argus are path where previous board locates)" 
    exit
}
if [[ $# -ne 2 && $# -ne 4 ]];then
    echo "Invalid argc:"$#
    usage
else
    case $# in
        "2")
            long_c=`echo $1 | awk -F "[-_]" '{print NF}'`
            short_c=`echo $2 | awk -F "[-_]" '{print NF}'`
            max_count=$long_c
            long=$1
            long_addr="."
            short=$2
            short_addr="."
            ;;
        "4")
            long_c=`echo $1 | awk -F "[-_]" '{print NF}'`
            short_c=`echo $3 | awk -F "[-_]" '{print NF}'`
            max_count=$long_c
            long=$1
            long_addr=$2
            short=$3
            short_addr=$4
            ;;
    esac
fi
    
echo "Begin to compare board:"$long" vs "$short

COMPARE_DIR="kernel,u-boot15,u-boot64,chipram,device"


if [[ $long_c -lt $short_c ]];then
    max_count=$short_c
    var_temp=$long
    long=$short
    short=$var_temp
    var_temp=$long_addr
    long_addr=$short_addr
    short_addr=$var_temp
fi

long_t=`echo $long | awk -F "[-_]" '{print $1}'`
long_t_u=`echo $long_t | tr 'a-z' 'A-Z'`

short_loc=~/temp/$short
long_loc=~/temp/$long

short_grep=`echo $short | sed 's/[-_]/\\\S\*/g'`
long_grep=`echo $long | sed 's/[-_]/\\\S\*/g'`

short_find=`echo $short | sed 's/[-_]/\*/g'`
long_find=`echo $long | sed 's/[-_]/\*/g'`

mkdir -p $short_loc $long_loc

dir_max_count=`echo $COMPARE_DIR |awk -F "," '{print NF}'`
for ((i=1;i<=$dir_max_count;i++))
do
    dir=`echo $COMPARE_DIR |awk -F "," -v idx=$i '{print $idx}'`
    echo $i":Scanning directory "$dir

    for((j=1;j<=2;j++))
    do
        if [[ j -eq 1 ]];then
            ntmp=$short_loc
            key_f=$short_find
            key_g=$short_grep
            res_dir=$short_addr/$dir
        else
            ntmp=$long_loc
            key_f=$long_find
            key_g=$long_grep
            res_dir=$long_addr/$dir
        fi
        echo -e "\tFinding dir/file by name:"$key_f" under:"$res_dir
        for d in `find $res_dir -name "*${key_f}*"`
        do
            echo -e "\t\tFound :"$d
            new_dir=$(dirname $d)
            mkdir -p $ntmp/$new_dir
            cp -rf $d $ntmp/$new_dir
        done
        echo -e "\tFinding dir/file by name done!"
        echo -e "\tSearching file by content:"$key_g" under:"$res_dir
        for file in `egrep "$key_g" --exclude-dir=".git" -ri $res_dir |awk -F':' '{print $1}'|uniq`
        do
            echo -e "\t\tFound :"$file
            new_dir=$(dirname $file)
            mkdir -p $ntmp/$new_dir
            cp -f $file $ntmp/$new_dir/
        done
        echo -e "\tSearching file by content done!"
    done
    
    for ((k=1;k<=$max_count;k++))
    do
        token1=`echo $short | awk -v idx=$k -F "[-_]" '{print $idx}'`
        token2=`echo $long | awk -v idx=$k -F "[-_]" '{print $idx}'`
        if [[ $token1 != $token2 ]];then
            for name in `find $long_loc/$dir -type d -name "*$token2*"`
            do
                if [[ $token1 = "" ]];then
                    new_name=`basename $name| sed "s/[-_]$token2//g"`
                else
                    new_name=`basename $name| sed "s/$token2/$token1/g"`
                fi
                mv -f $name $(dirname $name)/$new_name
            done
            for name in `find $long_loc/$dir -type f -name "*$token2*"`
            do
                if [[ $token1 = "" ]];then
                    new_name=`basename $name| sed "s/[-_]$token2//g"`
                else
                    new_name=`basename $name| sed "s/$token2/$token1/g"`
                fi
                mv -f $name $(dirname $name)/$new_name
            done
            for file in `grep $token2 -ri $long_loc/$dir| awk -F ':' '{print $1}'|uniq`
            do
                echo -e "\tModifing:$file"
                t_u1=`echo $token1 | tr 'a-z' 'A-Z'`
                t_u2=`echo $token2 | tr 'a-z' 'A-Z'`
                if [[ $token1 = "" ]];then
                    sed -ri "/$long_t|$long_t_u/{s/\S$token2//g}" $file
                    sed -ri "/$long_t|$long_t_u/{s/\S$t_u2//g}" $file
                else
                    sed -ri "/$long_t|$long_t_u/{s/$token2/$token1/g}" $file
                    sed -ri "/$long_t|$long_t_u/{s/$t_u2/$t_u1/g}" $file
                fi
            done
        fi
    done
    diff -ru $short_loc/$dir $long_loc/$dir >~/temp/$dir.diff
done
echo "Compare finished,please search ~/temp/*.diff for detail"
