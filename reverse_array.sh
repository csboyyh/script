#!/bin/bash

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

array=(5 6 7 8 9)

arg1=$(echo ${array[*]})

echo $arg1

ret=($(reverse_array $arg1))

echo "ret:"${ret[*]}

