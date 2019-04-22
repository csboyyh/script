#!/bin/bash

gerrit_query="ssh -p 29418 he.yang@review.source.unisoc.com gerrit query "

function g_query
{
    cond=`echo $@ | sed 's/[ :]/_/g'`
    echo "cond:"$cond
    `$gerrit_query $@>commit_by_$cond.info`
    size=`grep "^change" commit_by_$cond.info |wc -l`
    echo "queried $size commits"
    while true;do
        $gerrit_query $@ -S $size >>commit_by_$cond.info
        tsize=`grep "^change" commit_by_$cond.info |wc -l`
        echo "queried $tsize commits"
        if [ $tsize -eq $size ];then
            echo "no more commits,exit"
            break;
        else
            echo "continue:"$size
            let size=tsize
        fi

    done
    sed -i 's/^[\t ]*//g' commit_by_$cond.info
    format_commit commit_by_$cond.info
}

function diff_query
{
    size=`grep "^change" $1 |wc -l`
    tsize=`grep "^change" $2 |wc -l`
    if [ $size -gt $tsize ];then
        let diff=size-tsize
    else
        let diff=tsize-size
    fi
    head -n $diff $1>diff.info 
}
function format_commit
{
    echo -e "project\tid\towner\turl\tcommitMsg\tCreateTime\tStatus">$1_result.info
    awk -F":" 'BEGIN{project="";id="";number="";name="";url="";commitMsg="";CreateTime="";Status=""}
    {
        if($1=="project"){
            project=substr($2,2)
        }    
        if($1=="id"){
            id=$2
        }    
        if($1=="email"){
            name=$2
        }    
        if($1=="url"){
            url=$2":"$3
        }    
        if($1=="commitMessage"){
            commitMsg=$2
        }    
        if($1=="createdOn"){
            CreateTime=substr($2,1,10)
        }    
        if($1=="status"){
            status=$2
            print project"\t"id"\t"name"\t"url"\t"commitMsg"\t"CreateTime"\t"status
        }    
    }
    ' $1>>$1_result.info

}
