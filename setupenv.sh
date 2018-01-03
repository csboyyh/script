#!/bin/sh

function sh_sync
{
    dest_dir=~/project/$1
    if [ -d $1 ];then
        repo sync -n -j8 -cq;repo sync-server -l -j32 $1
    else
        mkdir -p $dest_dir
        cd $dest_dir
        repo init -u gitadmin@gitmirror.spreadtrum.com:android/platform/manifest.git -b $1
        repo sync -n -j8 -cq;repo sync-server -l -j32
        if [ $# -gt 2 ];then
            sh_tags $dest_dir
        fi
    fi
}
function sh_tags
{
    srcdir=`ls`

    find $srcdir -name "*.h" -o -name "*.c" -o -name "*.h" -o -name "*.s" -o -name "*.cpp" -o -name "*.java"  -prune >cscope.files
    cscope -bkq -i cscope.files

    ctags -R --c++-kinds=+p --fields=+iaS --extra=+q -L cscope.files

    echo -e "!_TAG_FILE_SORTED\t2\t/2=foldcase/" > filenametags
    find $srcdir -not -regex '.*\.\(png\|gif\)' -type f -printf "%f\t%p\t1\n" | \
    sort -f >> filenametags
}
function sh_push
{
    if [ -d ".git" ];then
        branch=`repo info . | awk '/revision/{print $3}'`
        repo_name=`repo info . | awk '/Project/{print $2}'`
        who=`git config --get user.name`
        git push ssh://$who@review.source.spreadtrum.com:29418/$repo_name HEAD:refs/for/$branch
    else
        echo "This is not repository dir"
    fi
}
function sh_dtb
{
    echo "Interpretate all output dtb to dts"
    for file in `find out -name *.dtb`
    do
        dtc -I dtb -O dts -o $(basename $file).dts $file
    done

}
function sh_crash
{
    arch=$1
}
function sh_kernel
{
    echo 
    #kernelversion;strings ./sysdump.bin |grep GCC
}
function sh_setup
{
    name=$(basename `pwd`)
    if [[ $name = *7* ]]
    then
        /usr/local/bin/change_to_v7.sh
    elif [[ $name = *6* || $name = *5* ]]
    then
        /usr/local/bin/change_to_5-6.sh
    else
        echo "Not code root,do nothing"
    fi
}
function sh_top
{
    history | awk '{print $2}'|sort |uniq -c | sort -gr | head -n 10
}
function sh_cmd
{
    if [ $# -lt 3 ];then 
        echo "Usage:sh_cmd [-j job_count] cmd agrs"
        exit 1
    fi
    case $1 in

    esac
}
