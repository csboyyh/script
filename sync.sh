#!/bin/sh

mkdir ~/project/$1

cd ~/project/$1

repo init -u gitadmin@gitmirror.spreadtrum.com:android/platform/manifest.git -b $1

repo sync -d -c -j4 2>&1 | tee sync.log

~/project/script/config .

#push;git push ssh://he.yang@review.source.spreadtrum.com:29418/device/sprd/scx35l HEAD:refs/for/sprdroid6.0_kaios_16c
#dtb;dtc -I dtb -O dts -o xx.dts sprd-scx35l_sp9820a_5c10_marlin.dtb
#x86crash;crash_x86_64 -m phys_base=0x34200000 sysdump.bin  ../../symbols/vmlinux --cpus 8
#kernelversion;strings ./sysdump.bin |grep GCC
#intel;source /usr/local/bin/ICC.sh
#rename;find . -name "*he*" -exec rename 's/he/yang/' {} \;
#setupenv;/usr/local/bin/change_to_v7.sh
#searchcmd;cat ~/project/script/sync.sh | sed 's/#//'|grep change
