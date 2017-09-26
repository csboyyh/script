#/bin/bash
##############################################################################
#
#   File          : boardmaker.sh
#   Author(s)     : xiaotong.lu <enck@spreadtrum.com>
#   Description   :
#
#
#
#
#   Copyright (c) 2017 xiaotong.lu
#
###############################################################################

function print_help()
{
  echo "-h: cmd help"
  echo "-c: copy ref board from project and create new board
	./boardmaker.sh -c  [ref board] [new board]"
  echo "-t: copy new board to project
	./boardmaker.sh -t "
  echo "-a: one key create board
	./boardmaker.sh -a  [ref board] [new board]"
}



function boardcopyout()
{

	echo "old="$1
        perl boardcopyout.pl dir=../../device    old=$1
	perl boardcopyout.pl dir=../../kernel    old=$1

}

function boardcopyout2()
{

	echo "old="$1

    	perl boardcopyout2.pl dir=../../device    old=$1
	perl boardcopyout2.pl dir=../../kernel    old=$1
    	perl boardcopyout2.pl dir=../../u-boot15  old=$1
	perl boardcopyout2.pl dir=../../chipram   old=$1
}


function boardcopyoutsecond()
{

        echo "old="$1

				if [  -d "../../u-boot15" ];then
				        perl boardcopyout.pl dir=../../u-boot15  old=$1
				        echo "has u-boot15!!"
				elif  [  -d "../../u-boot64" ];then
				        perl boardcopyout.pl dir=../../u-boot64  old=$1
				        echo " has u-boot64!!"
				elif  [  -d "../../u-boot" ];then
				        perl boardcopyout.pl dir=../../u-boot    old=$1
				        echo " has u-boot!!"
				else
				        echo "file maybe is not in correct dir,please put it to android top dir!!"
				fi

				perl boardcopyout.pl dir=../../chipram   old=$1
}


function boardcreate()
{
	echo "old="$1"   new="$2
	perl boardrename.pl   dir=diffpack/new    old=$1  new=$2
        #echo " return value :$?"

	if [ $? -ne 4 ];then
	  	echo " boardcompare.pl"
		perl boardcompare.pl  dir=diffpack/new    old=$1  new=$2
	fi
}


function boardcreatesecond()
{
        echo "boardcreatesecond:old="$1"   new="$2
	perl boardrename.pl   dir=diffpack/new    old=$1  new=$2
        perl boardcompare.pl  dir=diffpack/new/chipram    old=$1  new=$2
	if [  -d "../../u-boot15" ];then
        	perl boardcompare.pl  dir=diffpack/new/u-boot15    old=$1  new=$2
		echo "has u-boot15!!"
	elif  [  -d "../../u-boot64" ];then
		perl boardcompare.pl  dir=diffpack/new/u-boot64    old=$1  new=$2
        	echo " has u-boot64!!"
	elif  [  -d "../../u-boot" ];then
                perl boardcompare.pl  dir=diffpack/new/u-boot      old=$1  new=$2
                echo " has u-boot!!"
	else
        	echo "file maybe is not in correct dir !!!"
	      fi

}


function boardcopyin()
{
        #echo "dir="$1
	perl  boardcopyin.pl  dir="../.."
}


#程序的入口
workdir=$PWD
echo $workdir



while getopts "h:b:c:t:a:s:r:" OPT;do
 case "$OPT" in
   "h")
    		print_help
	;;
   "b")
		boardcopyout2 $2
	    echo "board copyout 2"
	;;
   "c")
		boardcopyout $2

        	CHIRAM_KEYWORD=`cat boardkey.txt | awk '/UBOOT/'|awk '{print $2}'`
	         echo "-$2-  -$CHIRAM_KEYWORD-"
		if [[ $CHIRAM_KEYWORD == *$2* ]] || [[ ! -n $CHIRAM_KEYWORD ]];then
			echo ">>>include"
                        boardcopyoutsecond $2
                        boardcreate  $2 $3
		else
			echo "no include"
			boardcreate  $2 $3
			boardcopyoutsecond $CHIRAM_KEYWORD
			boardcreatesecond  $CHIRAM_KEYWORD $3
		fi
		echo "board copyout and create board"
	;;
   "t")
                boardcopyin  $2
		echo "copy board to project"
	;;
   "a")
		boardcopyout $2
		boardcreate  $2 $3
		boardcopyin  $2
	 	echo "create board finished !!!"
  	;;
   "s")
		boardcopyout $2
		perl boardsubrename.pl   dir=diffpack/new    old=$2  new=$3
		echo "board copyout and create subboard"
	;;
   "r")
                perl boardrename.pl   dir=diffpack/new    old=$2  new=$3
                echo "board rename"
        ;;

   "?")
	echo "unkonw argument"
        ;;

 esac
done



echo "------------------------------------------"
#echo "Project path	: "$2
echo "Reference Board	: "$2
echo "------------------------------------------"

echo "------------------------------------------"
echo "New Board name	: "$3
echo "------------------------------------------"
