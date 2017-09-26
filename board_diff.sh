#!/bin/sh

echo now differ $1 $2

dir1=`find device/sprd -name $1`
echo "board path:"$dir1

index=1
uboot15="UBOOT_TARGET_DTB UBOOT_DEFCONFIG TARGET_BOOTLOADER_BOARD_NAME"
chipram="CHIPRAM_DEFCONFIG"
kernel="TARGET_DTB KERNEL_DEFCONFIG"

echo output chipram diff chipram.diff >>>>>>

while((true))
do
temp=`echo $chipram |awk '{print $index}'`
if [ $temp!=NUL ]
then
    dest_file=`grep $temp -rn dir1 | awk '{print $3}'`
else
    break
fi
echo "chipram file $index:$dest_file">>chipram.diff
file_path_board1=`find chipram -name $dest_file*` 
file_path_board2=`echo $file_path_board1 | sed "s/$1/$2/g"`
diff -c `echo $file_path_board1 |sed -n "$indexP"` `echo $file_path_board2 |sed -n "$indexP"` >>chipram.diff
echo "end <<<<<<<" >>chipram.diff
let "index+=1"
done
