#!/bin/bash

echo "Usage:create_patch.sh [commit-new] [commit-old] [patch-location] [patch-name]"
echo "commit-new:default HEAD,commit-old:default HEAD~1"
echo "patch-location:default ~/project/patch patch-name:default:(date)"
commit_new=HEAD
commit_old=HEAD~1
patch_location=~/project/patch
patch_name=$(date +%Y%m%d%H%M%S)

git status

if [ $? -lt 0]
then
    echo "Error:This is a git repo"
    return
fi

if [ $# -eq 4 ] then
    commit_new=$1
    commit_old=$2
    patch_location=$3
    patch_name=$(date +%Y%m%d%H%M%S)
elif [ $# -gt 0 ]then
    return
fi

mkdir -p $patch_location/$patch_name

git diff $(commit_new) $(commit_old) --name-status | awk '/[AMD]\s/{print $1 $2}'
