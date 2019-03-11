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
fetch_cmd="git fetch ssh://$user@review.source.unisoc.com:29418/"
cherry_fetch="git cherry-pick FETCH_HEAD"

############# used specified,need modify by user
user="he.yang"
pswd="Yh87@sprdj" #password
suser="$domain\\$user%$pswd"
idh_pattern="W([0-9]{2}\.){2}[0-9](_P[0-9])?$"
gerrit_pattern="^[0-9]{6,7}$"
#################################

#########
#
#       1 argument
#
#########

function get_gerrit_info
{
        unset src_branch src_project src_revision src_ref src_status
        unset dest_branch dest_project dest_revision dest_ref dest_status dest_group
    eval `ssh -p 29418 "$user$gurl" "$gq$1 $patch_set"|sed 's/\s//g' |awk -F ":" -v src=$2 ' 
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
        END{
            if(src==1){
                print "src_branch="branch";src_project="project";src_revision="revision";src_ref="ref";src_status="status
            }
            else{
                print "dest_branch="branch";dest_project="project";dest_revision="revision";dest_ref="ref";dest_status="status
            }
        }'` 
    if [ $2 -eq 1 ];then
        echo -e "gerrit src info\n \tbranch:"$src_branch"\n\tproject:"$src_project"\n\trevision:"$src_revision"\n\tref:"$src_ref"\n\tstatus:"$src_status 
        export src_branch src_project src_revision src_ref src_status
    else
        echo -e "gerrit dest info\n \tbranch:"$dest_branch"\n\tproject:"$dest_project"\n\trevision:"$dest_revision"\n\tref:"$dest_ref"\n\tstatus:"$dest_status 
        dest_group="sprd"
        export dest_branch dest_project dest_revision dest_ref dest_status dest_group
    fi
}

function get_idh_info
{
    unset dest_branch dest_project dest_revision dest_ref dest_status
    if [ `echo $1 |egrep $gerrit_pattern` ];then
        get_gerrit_info $1 0
        return
    fi
    if [ ! `echo $1 | egrep $idh_pattern` ];then
        echo "illegal idh version"
        return
    fi
    patch_prepare
    if [ ! -f $manifest_repo/$1_manifest.xml ];then
        echo "No buffered manifest,start to find it"
        if [ ! -f $work_dir/$idh_list ];then
            echo "No buffered idh list,start to fectch idh list from hudson"
            smbclient -c "recurse;ls" $hds -U $suser >$work_dir/$idh_list
        else
            if ! grep $1 -i $work_dir/$idh_list -q ;then
                echo "Not found $1 in buffered idh list,start to update idh list"
                smbclient -c "recurse;ls" $hds -U $suser >$work_dir/$idh_list
            fi
        fi
        dest_idh=`egrep "^\S.*$1$" -i $work_dir/$idh_list`
        if [ -z "$dest_idh" ];then
            echo "Do not find matched($1) idh "
            return
        fi
        echo "Start to fetch idh manifest snap"
        smbclient -c "get $dest_idh\\IDH\\manifest.xml $manifest_repo/$1_manifest.xml" $hds -U $suser 
        sed -i 's/^[ \t]*//g' $manifest_repo/$1_manifest.xml
        sed -i 's/["<>]//g' $manifest_repo/$1_manifest.xml
        sed -i 's/\/$//g' $manifest_repo/$1_manifest.xml
    fi

    if [ -z "$src_project" ];then
        dest_project=$2
    else
        dest_project=$src_project
    fi
    eval `grep $dest_project $manifest_repo/$1_manifest.xml |awk -F"=| " '{print "dest_revision="$7";dest_group="$9";dest_branch="$11}'`
    echo -e "dest(idh) info:\n\tdest_branch=$dest_branch\n\tdest_revision=$dest_revision\n\tdest_group=$dest_group"
    if [ "$dest_branch"x = x ];then
        echo "Not found $src_project in IDH release manifest"
        return
    fi
    dest_ref="none"
    export dest_revision dest_group dest_branch dest_project dest_ref
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
           echo -e "Pick commit($1) fail,fix merge conflicts mannually(use another ssh session)"
           echo -e "\tcode location:$work_dir/$dest_branch/$dest_project"
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
function cherry_pick_unmerged_gerrit
{
    if [ ! `echo $1 |egrep "[0-9]{6,8}"`];then
        echo "invalid gerrit"
        return
    fi
    get_gerrit_info $1 0
    pick_gerrit "dest" "false"
}
function pick_gerrit
{
    if [ $1 = "dest" -a "$dest_ref"x != "none"x ];then
        if [ $dest_status != "MERGED" ];then
            eval `echo "$fetch_cmd$dest_branch $dest_ref"`
            cherry_pick "FETCH_HEAD"
            dest_revision=`git log |grep "^commit"|awk '{print $2}'|head -n 1`
            dest_status="MERGED"
        fi
    elif [ $1 = "src" ];then
        if [ $src_status != "MERGED" ];then
            git reset --hard $dest_revision>/dev/null
            eval `echo "$fetch_cmd$src_branch $src_ref"`
            cherry_pick "FETCH_HEAD"
            src_revision=`git log |grep "^commit"|awk '{print $2}'|head -n 1`
            src_status="MERGED"
        elif [ $2 = "true" ];then
            git reset --hard $dest_revision>/dev/null
            cherry_pick $src_revision
            src_revision=`git log |grep "^commit"|awk '{print $2}'|head -n 1`
        fi
    fi
}

function merge_gerrit_base_idh
{
    local force_patch="false"
    if [ "$dest_project"x != "$src_project"x ];then
        echo "different project src:$src_project dest:$dest_project"
        echo "stop directly"
        return
    fi
    if [ "$dest_branch"x != "$src_branch"x ];then
        echo "different branch src($src_branch),dest($dest_branch)"
        if [ "$dest_branch"x != x ] ;then
            echo "do you want to force to create patch(input \"y\" or \"n\")"
            read option
            if [ "$option"x = "y"x ];then
                force_patch="true"
            else
                "stop creating patch"
                return
            fi
        else
            return
        fi
    fi

    mkdir -p $work_dir/$dest_branch

    cd $work_dir/$dest_branch
    echo "Start to fetch $dest_branch code"
    repo init -u $repo_info -b $dest_branch -q
    repo sync -J24 -c $dest_project --force-sync -q
    echo "Sync done"

    cd $work_dir/$dest_branch/$dest_project
    
    pick_gerrit "dest" $force_patch
    
    if [ $force_patch = "true" ];then
    
        echo "Start to fetch $src_branch code"
        git fetch korg $src_branch
        echo "Sync done"
    fi
    
    pick_gerrit "src" $force_patch
    commit_list="since_$2_to_gerrit_$1_commit.list"
    git log "$dest_revision..$src_revision" --reverse |grep "^commit">$work_dir/$commit_list
    
    if echo $dest_group | grep "idh" ;then
        bin_names=""
        files=""
        echo -e "This gerrit was released by binary files in IDH\n"
        for mfile in `git show $src_revision --name-status | awk '/^[AMD]\s/{print $2}'`
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
        echo -e "There are $count commits between src and dest,please confirm if your"
        echo -e "\tgerrit depend on it,if yes,input \"y\",if no input \"n\",or \"more\" for" 
        echo -e " \tdetail info check(equal to git show <commit>)"
        sleep 2
        git reset --hard  $dest_revision>/dev/null

        for commit in `cat $work_dir/$commit_list|awk '{print $2}'`
        do
            git show $commit --name-status
            while true ;
            do
                if [ "$commit" != "$src_revision" ];then
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
        patch_location=$(create_patch $work_dir/$dest_branch/$dest_project $dest_revision "HEAD")
    elif [ $count -eq 1 ];then
        patch_location=$(create_patch $work_dir/$dest_branch/$dest_project $dest_revision "HEAD")
    else
        echo "invalid case,there is no commit between $src_revision and $dest_revision"
        return
    fi
    
    echo -e "Please confirm if there is dependent commit in other repos"
    echo -e "\tif there is,input depended gerrit ID,or any else if there is not"
    read option
    if [ `echo "$option" | egrep "[a-f0-9]{4,40}"` ];then
        patch_release $option $2
    else
        echo "Create patch result for patch location:"$patch_location
    fi
}
function locate_git_and_repo
{
    if repo info .>/dev/null ;then
       repo info . | sed 's/[\t ]//g'|awk -F":" '
        BEGIN{branch="";project="";mount_path=""}
        {
            if($1=="Manifestbranch")
            {
                branch=$2
            }
            if($1=="Project")
            {
                project=$2
            }
            if($1=="Mountpath")
            {
                mount_path=$2
            }
        }
        END{print "patch_branch="branch";patch_project="project";mount_path="mount_path}
       '
   elif git status>/dev/null ;then
        local path_len=`expr length $(pwd)`
        local cur_pos=$(pwd)
        local git_pos=""
 
        while path_len > 0
        do
            last=$(basename $cur_pos)
            last_size=`expr length $last`
            if [ -d  $cur_pos/.git ];then
                git_pos=$cur_pos
                break;
            fi
            cur_pos=`expr ${cur_pos:0:path_len-last_size-1}`
            let path_len=`expr length $cur_pos`
        done
        echo "patch_branch=master;patch_project=${git_pos:1};mount_path=$git_pos"
    else
        echo "patch_branch=\"\";patch_project=\"\";mount_path=\"\""
    fi
}

#1:abosolute path for git
#2:old commit
#3:new commit
function create_patch
{
    if [ $# -lt 3 -o ! `echo $1 | egrep "^\/"` -o ! `echo $2|egrep "^[a-f0-9]{4,40}$"` ];then
         echo "two few args,1,abs path of git;2,old commit;3,new commit"
         return
    fi
    if [ "$3"x = "HEAD"x ];then
        head=`git log |grep "^commit"|awk '{print $2}'|head -n 1`
    elif echo $3 |egrep "[a-f0-9]{4,40}";then
        head=$3
    else
        echo "invalid 3rd arg,only commit sha(at least front 4char) and \"HEAD\" accepted"
        return
        head=""
    fi 
    cd $1
    eval `locate_git_and_repo`
    
    if [ "$patch_project"x = x -o "$mount_path"x = x ];then
        echo "invalid path,not find git"
        return
    fi
    patch_dir=$work_dir/output/$(date +%Y%m%d%H%M)_$patch_branch
    mkdir -p $patch_dir/new/$patch_project
    mkdir -p $patch_dir/old/$patch_project

    project=`echo $patch_project | sed 's/\//./g'`
    
    cd $mount_path

    git diff $2 $head >$patch_dir/$project".patch"
    git log $2..$head|sed '/^[\t ]*Bug[\t ]/,/^[\t ]*Change-Id:/ p' -n | sed 's/^[\t ]*//g'>$patch_dir/commit-msg.txt
    
    git reset --hard $2>/dev/null
    for line in `git diff $2 $head --name-status |awk '/^[AMD]\s/{print "opm="$1";file="$2";"}'`
    do
        eval `echo $line`
        dir_name=$(dirname $file)
        if [ $opm = "M" -o $opm = "D" ];then 
           mkdir -p $patch_dir/old/$patch_project/$dir_name
           cp $file $patch_dir/old/$patch_project/$dir_name
        fi
    done
    git reset --hard $head>/dev/null
    for line in `git diff $2 $head --name-status |awk '/^[AMD]\s/{print "opm="$1";file="$2";"}'`
    do
        eval `echo $line`
        dir_name=$(dirname $file)
        if [ $opm = "M" -o $opm = "A" ];then 
           mkdir -p $patch_dir/new/$patch_project/$dir_name
           cp $file $patch_dir/new/$patch_project/$dir_name
        fi
    done
    cd $patch_dir
    tar -czf $project.tar.gz *
    echo $patch_dir
}
#1,git repo absolute path
#2,patch.tar.gz
function patch_apply
{
    local patch_tmp=$work_dir/$(date +%Y%m%d%H%M)
    if [ $# -lt 2 ] || ! echo $1 | egrep "^\/" || ! echo $2 | egrep "\.tar\.gz$" ;then
         echo "too few args,1,abs path of git;2,<patch-name>.tar.gz"
         return
    fi
    cd $1
    eval `locate_git_and_repo`
    if [ "$patch_project"x = x -o "$mount_path"x = x ];then
        echo "invalid path,not find git"
        return
    fi
    cd $mount_path
    mkdir -p $patch_tmp
    tar -xzvf $2 -C $patch_tmp
    if ! git apply --reject $patch_tmp/*.patch ;then
        while true;
        do
            echo "please fix conflicts mannually"
            echo "have you finished fixing:\"y\"or\"\""
            read option
            if [ "$option"x = "y"x ];then
                break
            fi
        done
    fi
    git add --all
    if git commit -F $patch_tmp/commit-msg.txt;then
        echo "Finish apply patch successfully"
    else
        echo "Edit commit message must follow unisoc's patch format"
    fi
    rm -rf $patch_tmp
}
function script_usage
{
    echo "Usage:"
    echo "1 patch_release gerrit_id [IDH_verison|gerrit_id];like patch_release 560010 MOCORDROID9.0_Trunk_18C_W19.07.4"
    echo -e "\t it will create patch for front gerrit,base on second gerrit or IDH"
    echo "2 get_gerrit_info gerrit_id [0|1];it will get given gerrit info and export variaties"
    echo "3 get_idh_info idh_version [project_name];if use it alone,must two args,one is idh version like above one"
    echo -e "\t the other one is project name you want to find"
    echo "4 locate_git_and_repo: run under you any of git direction,it will report git info"
    echo "5 create_patch git_location(absolute path) old commit new commit"
    echo "6 patch_apply git_location(absolute path) <patch-name>.tar.gz;created by patch_release"
    echo "7 cherry_pick_unmerged_gerrit gerrit_id;cherry_pick unmerged gerrit"
    echo "patch_release is used to create patch,patch_apply is used to apply it"
    echo "patch_release will create patch or report IDH binary file names if gerrit resides idh repo"

}

function patch_release
{
    cur_pos=$(pwd)
    if [ $# -lt 2 ];then
        script_usage
        return
    fi
    patch_prepare
    if [ $? -ne 0 ];then
        return
    fi
    get_gerrit_info $1 1
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
    if [ $user != $who ];then
        echo "Modify script user variable;user your own"
        return 1
    fi
}


