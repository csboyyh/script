#!/bin/sh

function sh_sync
{
    dest_dir=~/project/$1
    mkdir -p $dest_dir
    cd $dest_dir
    repo init -u gitadmin@gitmirror.spreadtrum.com:android/platform/manifest.git -b $1
    repo sync -d -c -j4 2>&1 | tee sync.log
    sh_tags $dest_dir
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
    branch=
    repo=
    who=`whoami`
    git push ssh://$who@review.source.spreadtrum.com:29418/$repo HEAD:refs/for/$branch
}
function sh_dtb
{
    #convert all dtb object
    dtb_files=`find . -name "*.dtb"`
    dtc_files= `echo $dtb_files |sed "s/dtb/dtc/g"`
    
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
    /usr/local/bin/change_to_v7.sh
}
