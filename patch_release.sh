#!/usr/bin/bash

DEBUG="false"

DEBUG()
{
    if [ $DEBUG="true" ];then
        $@
    fi
}
#############work space directory,

work_dir="$HOME/patch_dir"
idh_list="idh.list"
manifest_repo=$work_dir"/manifest_repo"


#############unisoc db url info

gurl="@review.source.unisoc.com"
gq="gerrit query change:"
patch_set="--patch-sets"
hds="//10.0.1.110/hudson"
domain="spreadtrum"
repo_info="gitadmin@gitmirror.spreadtrum.com:android/platform/manifest.git"
fetch_cmd="git fetch ssh://$who@review.source.unisoc.com:29418/"
cherry_fetch="git cherry-pick FETCH_HEAD"

############# used specified,need modify by user
who="he.yang"
pswd="Yh87@sprdj" #password
suser="$domain\\$who%$pswd"

#################################

#########
#
#       1 argument
#
#########

function get_gerrit_info
{
    eval `ssh -p 29418 "$who$gurl" "$gq$1 $patch_set"|sed 's/\s//g' |awk -F ":" ' 
        BEGIN{branch="";project="";revision="";ref="";status="new"}
        {
            if($1=="branch"){
                branch=$2
            }
            if($1=="project"){
                project=$2
            }
            if($1=="revision"){
                revision=$2
            }
            if($1=="ref"){
                ref=$2
            }
            if($1=="status"){
                status=$2
            }
        }
        END{print "p_branch="branch";p_project="project";p_revision="revision";p_ref="ref";p_status="status}'` 
    echo -e "gerrit info\n \tbranch:"$p_branch"\n\tproject:"$p_project"\n\trevision:"$p_revision"\n\tref:"$p_ref"\n\tstatus:"$p_status 
    export p_branch p_project p_revision p_ref p_status
}

function get_idh_info
{
    patch_prepare
    unset idh_revision idh_group idh_branch
    if [ ! -f $manifest_repo/$1_manifest.xml ];then
        if [ ! -f $work_dir/$idh_list ];then
            smbclient -c "recurse;ls" $hds -U $suser >$work_dir/$idh_list
        else
            if grep $1 -i $work_dir/$idh_list -q ;then
                smbclient -c "recurse;ls" $hds -U $suser >$work_dir/$idh_list
            fi
        fi
        dest_idh=`egrep "^\S.*$1$" -i $work_dir/$idh_list`
        echo "search result:"$dest_idh
        if [ -z $dest_idh ];then
            echo "Do not find matched($1) idh "
        fi
        smbclient -c "get $dest_idh\\IDH\\manifest.xml $manifest_repo/$1_manifest.xml" $hds -U $suser 
        sed -i 's/^[ \t]*//g' $manifest_repo/$1_manifest.xml
        sed -i 's/["<>]//g' $manifest_repo/$1_manifest.xml
        sed -i 's/\/$//g' $manifest_repo/$1_manifest.xml
    fi

    if [ -z "$p_project" ];then
        p_project=$2
    fi
    eval `grep $p_project $manifest_repo/$1_manifest.xml |awk -F"=| " '{print "idh_revision="$7";idh_group="$9";idh_branch="$11}'`
    echo -e "idh info:\n\tidh_branch=$idh_branch\n\tidh_revision=$idh_revision\n\tidh_group=$idh_group"
    if [ "$idh_branch"x = x ];then
        echo "Not found $p_project in IDH release manifest"
        return
    fi
    export idh_revision idh_group idh_branch
}

function cherry_pick
{
    if ! git cherry-pick $1 >/dev/null;then
       eval `git status -s | awk '{print "emode="$1";efile="$2";"}'`
       case $emode in
           "UU")
           if ! egrep "<<<<<<<|>>>>>>>" $efile ;then
               echo "Auto fix conflicts,commit directly"
               git add --all
               git commit --no-edit
               echo "cherry-pick commit($1)successfully"
               sleep 1
               return
           fi
               ;;
       esac
       while true 
       do
           echo -e "Pick commit($1) fail,fix merge conflicts mannually"
           echo -e "\tcode location:$work_dir/$idh_branch/$p_project"
           echo -e "\tafter fix,use git add ;git commit then come back"
           echo "Have you fixed cherry-pick conflicts?\"y\" or \"n\""
           read option
           if [ "$option"x = "y"x ];then
               break
           else
               echo "please continue to fix between <<< ===are elder version"
                "==== <<<< are newer version,merge them mannually"
               continue
           fi
       done
    fi
    echo "cherry-pick commit($1)successfully"
    sleep 1

}
function pick_gerrit
{
    local tmp_revision=$p_revision
    local need_cherry="false"
    if [ $p_status != "MERGED" ];then
        eval `echo "$fetch_cmd$p_branch $p_ref"`
        tmp_revision="FETCH_HEAD"
        need_cherry="true"
    fi
    if [ $1 = "true" -o $need_cherry = "true" ];then
        git reset --hard $idh_revision>/dev/null
        cherry_pick $tmp_revision
        p_revision=`git log |grep "^commit"|awk '{print $2}'|head -n 1`
        p_status="MERGED"
    fi
}

function merge_gerrit_base_idh
{
    local force_patch="false"
    if [ "$idh_branch"x != "$p_branch"x ];then
        echo "different branch gerrit($p_branch),idh($idh_branch)"
        if [ "$idh_branch"x != x ] ;then
            echo "do you want to force to create patch(input \"y\" or \"n\")"
            read option
            if [ "$option"x = "y"x ];then
                force_patch="true"
            else
                "stop create patch"
                return
            fi
        else
            return
        fi
    fi

    mkdir -p $work_dir/$idh_branch

    cd $work_dir/$idh_branch
    echo "Start to fetch $idh_branch code"
    repo init -u $repo_info -b $idh_branch -q
    repo sync -J24 -c $p_project --force-sync -q
    echo "Sync done"

    cd $work_dir/$idh_branch/$p_project
    
    if [ $force_patch = "true" ];then
    
        echo "Start to fetch $p_branch code"
        git fetch korg $p_branch
        echo "Sync done"
    fi
    
    pick_gerrit $force_patch
    commit_list="since_$2_to_gerrit_$1_commit.list"
    git log "$idh_revision..$p_revision" --reverse |grep "^commit">$work_dir/$commit_list
    
    if echo $idh_group | grep "idh" ;then
        bin_names=""
        files=""
        echo -e "This gerrit was released by binary files in IDH\n"
        for mfile in `git show $p_revision --name-status | awk '/^[AMD]\s/{print $2}'`
        do
            echo "modified file:"$mfile
            file=$(basename $mfile)
            if [ `echo $file | egrep "(\.c|\.cpp|\.cc|\.java)$"` ];then
                mkfile=`grep $file -r . | grep "\.mk" |awk -F":" '{print $1}'`
            elif [ `echo $file |egrep "(\.h|\.mk)$"` ];then
                continue
            fi
            if [ -n "$mkfile" ];then
                echo "mkfile "$mkfile":"
                range=`egrep "$file|include" $mkfile -n |awk -F":" -v file=$file '
                BEGIN{pre_line=0;next_line=0;done=0}
                {
                    if(match($2,"include"))
                    {
                        if(done==0)
                        {
                            pre_line=$1
                        }
                        else
                        {
                            next_line=$1
                        }
                    }
                    if(match($2,file))
                    {
                        done=$2
                    }
                }
                END{print pre_line","next_line}'`
                echo "range:"$range
                bin_name=`sed "$range {/LOCAL_MODULE\s*:/p}"  $mkfile -n |sed 's/[\t ]//g'|awk -F":=" '{print $2}'` 
                echo "bin name:"$bin_name
                bin_names=$bin_names" $bin_name"
            else
                if [ ! `echo $file | grep "\.h$"` ];then
                    echo "not compile file,release $file directly"
                fi
            fi
            files=$files" $file"
        done
        echo -e "please send customer binary file($bin_names) compiled by files($files)\n"
        return
    fi
    count=`cat $work_dir/$commit_list |wc -l`
    if [ $count -gt 1 ];then
        echo -e "There are $count commits between idh and gerrit,please confirm if your"
        echo -e "\tgerrit depend on it,if yes,input \"y\",if no input \"n\",or \"more\" for" 
        echo -e " \tdetail info check(equal to git show <commit>)"
        sleep 2
        git reset --hard  $idh_revision>/dev/null

        for commit in `cat $work_dir/$commit_list|awk '{print $2}'`
        do
            git show $commit --name-status
            while true ;
            do
                if [ "$commit" != "$p_revision" ];then
                    echo -e "Dose your gerrit depend on it:(y/n/more)"
                    read option
                else
                    option="y"
                fi

                if [ $option = "n" ];then
                    sed -i "/$commit/d" $work_dir/$commit_list
                    break
                elif [ $option = "y" ];then
                    echo "Prepare to collect this commit:"$commit
                    cherry_pick $commit
                    break
                elif [ $option = "more" ];then
                    git show $commit
                    continue
                else
                    echo "please input legal options(y/n/more)"
                    continue
            fi
            done
        done
        patch_location=$(create_patch)
    elif [ $count -eq 1 ];then
        git reset --hard $p_revision
        patch_location=$(create_patch)
    else
        echo "invalid case,there is no commit between $p_revision and $idh_revision"
        return
    fi
    
    echo -e "Please confirm if there is dependent commit in other repos"
    echo -e "\tif there is,input depended gerrit ID,or any else if there is not"
    read option
    if [ `echo "$option" | egrep "[a-f0-9]{8,40}" ` ];then
        patch_release $option $2
    else
        echo "Create patch successully locates:"$patch_location
    fi
}
function create_patch
{
    patch_dir=$work_dir/output/$(date +%Y%m%d%H%M)_$idh_branch
    mkdir -p $patch_dir/new/$p_project
    mkdir -p $patch_dir/old/$p_project

    project=`echo $p_project | sed 's/\//./g'`
    
    cd $work_dir/$idh_branch/$p_project

    git diff $idh_revision HEAD >$patch_dir/$project".patch"
    git log $idh_revision..HEAD >$patch_dir/commit-msg.txt

    head=`git log |grep "^commit"|awk '{print $2}'|head -n 1`
    
    git reset --hard $idh_revision>/dev/null
    for line in `git diff $idh_revision $head --name-status |awk '/^[AMD]\s/{print "opm="$1";file="$2";"}'`
    do
        eval `echo $line`
        dir_name=$(dirname $file)
        if [ $opm = "M" -o $opm = "D" ];then 
           mkdir -p $patch_dir/old/$p_project/$dir_name
           cp $file $patch_dir/old/$p_project/$dir_name
        fi
    done
    git reset --hard $head>/dev/null
    for line in `git diff $idh_revision $head --name-status |awk '/^[AMD]\s/{print "opm="$1";file="$2";"}'`
    do
        eval `echo $line`
        dir_name=$(dirname $file)
        if [ $opm = "M" -o $opm = "A" ];then 
           mkdir -p $patch_dir/new/$p_project/$dir_name
           cp $file $patch_dir/new/$p_project/$dir_name
        fi
    done
    cd $patch_dir
    tar -czf $project.tar.gz *
    echo $patch_dir
}

function script_usage
{
    echo "Usage" 
}

function patch_release
{
    cur_pos=$(pwd)
    if [ $# -lt 2 ];then
        script_usage
    fi
    patch_prepare
    get_gerrit_info $1
    get_idh_info $2
    merge_gerrit_base_idh $1 $2
    cd $cur_pos
}

function patch_prepare
{
    if [ ! -d $work_dir ];then
        mkdir "$work_dir"
    fi

    if [ ! -d $manifest_repo ];then
        mkdir $manifest_repo
    fi
}


