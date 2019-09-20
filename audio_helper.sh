#!/system/bin/sh

function loop_check
{
    loop=0
    while true
    do
        echo "loop mark $loop">>/data/log.log
        date >>/data/log.log
        lookat -l 30 0x71000000 >> /data/log.log
        if cat /proc/asound/alli2s/pcm3p/sub0/status | grep RUNNING;then 
            cat /proc/asound/alli2s/pcm3p/sub0/status >>/data/log.log 
        else 
            cat /proc/asound/alli2s/pcm3p/sub0/status >>/data/log.log 
            logcat -d -b main >>/data/log.log 
        fi 
        status=`cat /proc/asound/alli2s/pcm3p/sub0/status`
        echo "loop:"$loop" play status:"$status
        let loop=loop+1
        sleep 2
    done
}
function check_i2s_card
{
   echo "check i2s card status:"
   if [ -d /d/asoc/all-i2s ];then
        echo "all-i2s card devices:"
        ls /d/asoc/all-i2s
        cat /proc/asound/alli2s/i2s-debug
        if cat /proc/asound/alli2s/*/sub0/status|grep RUNNING;then
            cat /proc/asound/alli2s/i2s-reg
        fi
   else
        echo "3rd party codec may register failed,check if there it is"
        cat /d/asoc/codecs
   fi
   echo "check pinctrl switch"
}
function check_card
{
    good_cards=("sprdphone" "alli2s" "saudiolte" "saudiovoip")
    card_num=`cat /proc/asound/cards |grep "^ [0-9]" |wc -l`
    for card in ${good_cards[@]}
    do
        if grep $card /proc/asound/cards -q;then
            echo "found $card"
        else
            echo "we miss $card"
            if [ $card = "alli2s" ];then
                check_i2s_card
            elif [ $card = "saudiolte" -o $card = "saudiovoip" ];then
                echo "miss modem related card,check modem status"
            fi
        fi
    done
}
function check_param
{
    cat /proc/asound/*/*/sub0/hw_params
    cat /proc/asound/*/*/sub0/sw_params
    echo "if are playing,but all result are closed,define RULES_DEBUG in sound/core/pcm_native.c"
    echo "then check the dmesg find the empty value cause your hw_params failed"
}
function enable_log
{
    echo "file soc-pcm.c +p">/d/dynamic_debug/control
    echo "file i2s.c +p">/d/dynamic_debug/control
    if [ $# -lt 2 ];then
        echo 7 >/proc/asound/sprdphone/asoc-sprd-debug
    fi
}
function dt_parse
{
    echo "parse $1 value:`busybox hexdump $1 -Cv`"
    echo "big endian:00 00 00 13=19"
}
function check_log
{
    #check_app_log;route;call;
    #check_kernel_log;headset,ext pa,codec,i2s
}
function check_asoc
{
    enable_log
    dmesg | grep ASoC >/data/dmesg.log
    if grep "min rate.*max rate" /data/dmesg.log -q;then
        echo "open device successfully,check hw_params"
        check_hw_params
    else
        if grep "No matching" /data/dmesg.log;then
            echo "codec and dai mismatch,check their dai_driver struct member"
        else
            grep "ASoC: can't" /data/dmesg.log
        fi
    fi

}
function basic_check
{
    check_card
    check_param
    check_i2s_card
}
function usage
{
    echo "avaiable func:"
    echo -e "\t check_card:check card status"
    echo -e "\t check_i2s_card:check alli2s card status"
    echo -e "\t check_param:check running device hw and sw param"
    echo -e "\t check_asoc:check pcm open status log"
    echo -e "\t enable_log:enable audio log"
    echo -e "\t check_log:check app/kernel audio special log"
}
