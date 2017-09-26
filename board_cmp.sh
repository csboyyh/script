#!/bin/sh

rm -rvf ~/project/temp/

#find board accurate diff part
token1=`echo $1 | awk -F '_' '{print $2}'`
token2=`echo $2 | awk -F '_' '{print $2}'`

echo "token1:$token1 token2:$token2"

board1_dir=`find device/sprd/ -name $1`
board2_dir=`find device/sprd/ -name $2`

dest1_dir=~/project/temp/$1
dest2_dir=~/project/temp/$2

mkdir -p ~/project/temp

cp -rf $board1_dir $dest1_dir
cp -rf $board2_dir $dest2_dir

rm -rf $dest1_dir/rootdir/system/etc/audio_params
rm -rf $dest2_dir/rootdir/system/etc/audio_params

board_file=`find $dest1_dir -name "*$1*" -type f`

for file in `echo $board_file`
do
    file_dst=$(basename $file)
    file_dst=`echo $file_dst | sed "s/$1/$2/g"`
    mv $file $(dirname $file)/$file_dst
done

for file in `grep $token1 -ri $dest1_dir | awk -F ':' '{print $1}'`
do
    echo "modify file:$file"
    sed -i "s/$token1/$token2/g" $file
done


diff -ru $dest2_dir $dest1_dir >>device.diff


echo "Scanning Kernel"
kernel_board1=`egrep "^TARGET_DTB|^KERNEL_DEFCONFIG" -rn $board1_dir |awk '{print $3}'`
kernel_board2=`egrep "^TARGET_DTB|^KERNEL_DEFCONFIG" -rn $board2_dir |awk '{print $3}'`

mkdir -p ~/project/temp/kernel/$1
mkdir -p ~/project/temp/kernel/$2

for file in $(echo $kernel_board2)
do
    echo file1:$file
    dest_file=`find kernel/arch -name "$file.dts"`
    cp $dest_file ~/project/temp/kernel/$2/$(basename $dest_file)
done

for file in $(echo $kernel_board1)
do
    echo file2:$file
    dest_file=`find kernel/arch -name "$file.dts"`
    base_name=$(basename $dest_file)
    base_name=`echo $base_name |sed "s/$token1/$token2/g"`
    cp $dest_file ~/project/temp/kernel/$1/$base_name
    sed -i "s/$token1/$token2/g" ~/project/temp/kernel/$1/$base_name
done

diff -ru ~/project/temp/kernel/$2 ~/project/temp/kernel/$1>>kernel.diff

echo "Scanning Uboot "

mkdir -p ~/project/temp/uboot/$1
mkdir -p ~/project/temp/uboot/$2

u1_file=`find u-boot15 -name "*$1*"`
u1_file=`echo "$u1_file\n"``find u-boot64 -name "*$1*"`
echo "u1_file:"$u1_file
u2_file=`find u-boot15 -name "*$2*"`


for file in `echo $u2_file`
do
    if [ -d $file ]
    then
        cp -rvf $file/* ~/project/temp/uboot/$2/
    else
        cp -vf $file ~/project/temp/uboot/$2/$(basename $file)
    fi
done

for file in `echo $u1_file`
do
    base_name=$(basename $file)
    base_name=`echo $base_name | sed "s/$token1/$token2/g"`
    if [ -d $file ]
    then
        cp -rvf $file/* ~/project/temp/uboot/$1/
    else
        cp -vf $file ~/project/temp/uboot/$1/$base_name
    fi
    sed -i "s/$token1/$token2/g" ~/project/temp/uboot/$1/*
done

find ~/project/temp/uboot/$1/ -name "*$token1*" |xargs rm -vf
diff -ru ~/project/temp/uboot/$2 ~/project/temp/uboot/$1 >>u-boot15.diff

upper_token1=$(echo $token1 | tr '[a-z]' '[A-Z]')
upper_token2=$(echo $token2 | tr '[a-z]' '[A-Z]')

echo "Scanning Chipram "

mkdir -p ~/project/temp/chipram/$1
mkdir -p ~/project/temp/chipram/$2

c1_file=`find chipram -name "*$1*"`
c2_file=`find chipram -name "*$2*"`


for file in `echo $c2_file`
do
    cp -rvf $file ~/project/temp/chipram/$2/$(basename $file)
done

for file in `echo $c1_file`
do
    base_name=$(basename $file)
    base_name=`echo $base_name | sed "s/$token1/$token2/g"`
    cp -rvf $file ~/project/temp/chipram/$1/$base_name
    if [ -d $file ]
    then
        sed -i "s/$token1/$token2/g" ~/project/temp/chipram/$1/$base_name/*
    else
        sed -i "s/$token1/$token2/g" ~/project/temp/chipram/$1/$base_name
    fi
done

diff -ru ~/project/temp/chipram/$2 ~/project/temp/chipram/$1>>chipram.diff
