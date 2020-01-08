#!/bin/sh

gurl="@review.source.unisoc.com"
gq="gerrit query change:"
patch_set="--patch-sets"
hds="//10.0.1.110/hudson"
domain="spreadtrum"
repo_info="gitadmin@gitmirror.spreadtrum.com:android/platform/manifest.git"
fetch_cmd="git fetch ssh://$who@review.source.unisoc.com:29418/"
cherry_fetch="git cherry-pick FETCH_HEAD"
who="he.yang"
pswd="Yh87@sprdj" #password
suser="$domain\\$who%$pswd"

function show_filc
{
    git show HEAD --name-status |awk '/[AMD]\s/{print $1,$2}'
}
function sh_get_gerrit_info
{
    eval `ssh -p 29418 "$who$gurl" "$gq$1 $patch_set" |sed 's/\s//g' | awk -F ":" '
        BEGIN{branch="";project="";revision="";ref="";status="new"}
        {
            if($1=="branch")
            {
                branch=$2
            }
            if($1=="project")
            {
                project=$2
            }
            if($1=="revision")
            {
                revision=$2
            }
            if($1=="ref")        
            {
                ref=$2
            }  
            if($1=="status")
            {
                status=$2
            }}
        END{print "branch="branch";project="project";revision="revision";p_ref="ref";status="status}'`
        echo "branch:"$branch

}
function sh_sync
{
    dest_dir=~/project/$1
    if [ -d $1 ];then
        cd $dest_dir
        repo sync -c -d -q -j24
    else
        mkdir -p $dest_dir
        cd $dest_dir
        if [[ $1 =~ "roid10"|"roidq" ]];then
            echo "Above q,use platform repo"
            repo_name="platform/manifest.git"
        else
            echo "Under q,use android/platform repo"
            repo_name="android/platform/manifest.git"
        fi
        repo init -u ssh://gitadmin@gitmirror.spreadtrum.com/$repo_name -b $1
        repo sync -c -d -q -j24
        #sh_tags $dest_dir
    fi
}
function sh_tags
{
    cd $1
    srcdir=`ls`

    find $srcdir -name "*.h" -o -name "*.c" -o -name "*.h" -o -name "*.s" -o -name "*.cpp" -o -name "*.java" -o -name "*.dts" -o -name "*.dtsi" -prune >cscope.files
    cscope -bkq -i cscope.files

    ctags -R --c++-kinds=+p --fields=+iaS --extra=+q -L cscope.files

    echo -e "!_TAG_FILE_SORTED\t2\t/2=foldcase/" > filenametags
    find $srcdir -not -regex '.*\.\(png\|gif\)' -type f -printf "%f\t%p\t1\n" | \
    sort -f >> filenametags
}
function sh_push
{
    git log >/dev/null
    if [ $? -eq 0 ];then
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
function sh_cvt
{
    echo $1 | sed "s:\\/:\#:g"
}
