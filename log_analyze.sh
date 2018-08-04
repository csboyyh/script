#!/bin/bash

function help
{ 
    echo -e "Usage:\n\t"
    echo -e "\t Parse known issue with symbolic log"
    echo -e "\t log_analyze.sh symbol_file|issue_log ylog_file"
}
function parse_db
{
    echo "Parsing:"$1
    symbols=`awk -F"," '/^(!#)/{print $1}' $1`
}
function unpack_log
{
    echo "First unpack ylog dir:"$1

    for file in `find $1 -name "*.py"`
    do
        chmod a+x $file
        echo "Unpacking:"$file
        $file
    done
}

if [ -f $1 -a -d $2 ];then
    parse_db $1
    unpack_log $2
    echo $symbols
else
    echo "invalid arguments"
    help
fi

