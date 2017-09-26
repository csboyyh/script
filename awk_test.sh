#!/bin/sh

dts1=`grep UBOOT_TARGET_DTB -r . | awk '{print $1}'` 
dts2=`grep UBOOT_TARGET_DTB -r . | awk '{print $2}'` 
dts3=`grep UBOOT_TARGET_DTB -r . | awk '{print $3}'` 
echo $dts1 "\n" $dts2 "\n" $dts3

