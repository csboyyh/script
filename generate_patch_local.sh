#!/bin/bash
######################################################
# user:summer.duan<summer.duan@spreadtrum.com>
# date:2014-01-25
# create Delta between git commits
# description:
echo " 根据提示输入一系列参数"
echo " 1，patch path:生成的patch文件保存的位置。"
echo " 2. repo path：要生成patch的仓库全路径"
echo " 3. commita：要生成patch的base版本的commit值"
echo " 4. commitb：要生成patch的新版本的commit值    "
######################################################

#workspace="/home/summerduan/repo/gitrepo/mypatch" #生成的patch文件存放的路径，比如:/home/apuser/repo/patch
echo "please input your patch path.like:/home/summerduan/repo/patch"
read workspace
#workspace=/home2/he.yang/tmp
if [ -z "$workspace" ]; then
  workspace="$(pwd)/patch"
  echo "default workspace:$workspace"
fi
echo "please input repopath.like:/home/summerduan/repo/sprdroid4.4_3.10/frameworks/base"
read repo
while [ -z "$repo" ]; do
  echo "repo path can not be empty."
  echo "please input repopath again."
  read repo
done
echo "please input one commit or tag.like:40sha1,or MOCORDROID4.1_3.4_TSHARK_13B_W14.04.4"
read commita
while [ -z "$commita" ]; do
 echo "commit can not be empty."
 echo "please input commit again."
 read commita
done
echo "please input another commit or tag."
read commitb
while [ -z "$commitb" ]; do
  echo "commit can not be empty."
  echo "please input commit again."
  read commitb
done

#repo=`pwd`
#commita="HEAD~1"
#commitb=HEAD
patchfolder=$(date '+%Y%m%d%H%M%S')
workspace="$workspace/$patchfolder"
if [ ! -d $workspace ]; then
  mkdir -p $workspace
fi

if [ ! -d "$repo" ]; then
  echo "Failure! $repo does not exist."
  exit 1
fi


fw="$workspace/readme"
echo > $fw
echo "repo:$repo" | tee -a $fw
echo "commita:$commita" | tee -a $fw
echo "commitb:$commitb" | tee -a $fw
echo "patch:$workspace"

# define delta file name
delta="Delta"
delta_path="$workspace/$delta"

# make delta file folder
cd $workspace
mkdir -p $delta_path

cd $repo
# get patch between commita and commitb
git diff --binary $commita $commitb >$delta_path/patch.txt

if [ ! -s "$delta_path/patch.txt" ]; then
  echo "Failure! please check commit value" | tee =a $fw
  exit 1
fi

git diff $commita..$commitb --name-status >> $fw

# get commita files and pack it
bfilelist=$(git diff $commita..$commitb --name-status | grep "^[D|M]" | grep -v pax_global_header | cut -c2- | sort)
echo "before:$bfilelist"

if [ "$bfilelist" ]; then
  git archive -o $delta_path/before.tar $commita $bfilelist
fi

# get commitb files and pack it
afilelist=$(git diff $commita..$commitb --name-status | grep "^[A|M]" | grep -v pax_global_header | cut -c2- | sort)
echo "after:$afilelist"
if [ "$afilelist" ]; then
  git archive -o $delta_path/after.tar $commitb $afilelist
fi

cd $workspace
tar -czf $delta.tgz $delta

