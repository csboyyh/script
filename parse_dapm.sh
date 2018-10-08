#!/bin/bash

function parse_dapm_struct
{
    if [ -d dapm ];then
        rm -rf dapm
        mkdir dapm
    fi
    while read line
    do
        array=(${line//:/ })
        #echo "widget:"${array[0]}
        case ${array[0]} in
            out)
                echo ${array[${#arry[@]}-1]}>>dapm/$filename"_out"
                ;;
            in)
                echo ${array[${#arry[@]}-1]}>>dapm/$filename"_in"
                ;;
            stream)
                continue
                ;;
            *)
                filename=${array[0]}
        esac
    done < $1
}
path_count=0
idx=0

function reverse_array
{
    local p_arr=($(echo "$@"))
    local r_arr=${p_arr[@]}
    local size=$[ $# - 1 ]
    for ((i=0;i<=$size;i++))
    do  
         r_arr[$i]=${p_arr[$size-$i]}
     done
     echo ${r_arr[*]}
}

function recrusive_dapm_path
{
    local widget=$1
    local dir=$2
    echo "widget:"$widget" dir:"$dir" idx:"$idx
    path[$idx]=$widget
    if [ ! -e dapm/$widget"_"$dir ];then
        if [ $dir == "out" ];then
            echo $path_count":"${path[@]}| tee -a path.txt
        else
            arg=$(echo ${path[*]})
            ret=($(reverse_array $arg))
            echo $path_count":"${ret[*]}| tee -a path.txt
        fi
        let path_count++
        unset path[$idx]
        return
    fi

    while read itera
    do
        let idx++
        echo "itera:"$itera
        recrusive_dapm_path $itera $dir
        unset path[$idx]
        let idx--
    done < dapm/$widget"_"$dir
}
#parse_dapm_struct dapm.txt
#recrusive_dapm_path Normal-Playback out
recrusive_dapm_path $1 $2
