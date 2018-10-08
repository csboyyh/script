#!/system/bin/sh

card_count=0

info_dir=/data/audio_info
card_db=/data/audio_info/card.info
play_db=/data/audio_info/playing.info
dapm_db=/data/audio_info/dapm.info
code_dai_db=/data/audio_info/codec_dai.info
gpio_db=/data/audio_info/gpio.info
tiny_db=/data/audio_info/tinymix.info

Bbox()
{
    if [ $bbox = "true" ];then
        busybox $@
    fi
}
function prepare
{
    if busybox --help>/dev/null;then
        bbox="true"
    fi
    if [ -d $info_dir ];then
        rm -rf $info_dir
    fi
    mkdir $info_dir
}

function list_codecs_dais_info
{
    Bbox cat /d/asoc/codecs | Bbox tee -a $code_dai_db
    Bbox cat /d/asoc/dais   | Bbox tee -a $code_dai_db
}

function list_gpio_info
{
    Bbox cat /d/gpio | Bbox tee -a $gpio_db
}

function list_tinymix_status
{
    if [ $card_count -eq 0 ];then
       probe_card_device_info
    fi
    
    for i in `Bbox seq 0 $card_count`
    do
        tinymix -D $i | Bbox tee -a $tiny_db
    done
}

function list_dapm_context
{
    local i=0
    if [ $card_count -eq 0 ];then
        probe_card_device_info
    fi

    while (($i<$card_count))
    do
        echo "card:"${card_info[$i]}
        if [ -d /d/asoc/${card_info[$i]} ];then
            cat /d/asoc/${card_info[$i]}/dapm/* | Bbox tee -a $dapm_db
            cat /d/asoc/${card_info[$i]}/*/dapm/* | Bbox tee -a $dapm_db
        fi
        let i++
    done
}

function print_playing_status
{
    for path in `Bbox find /proc/asound/ -name sub0`
    do 
        echo $path" status below=========="| Bbox tee -a $play_db
        cat $path/status    | Bbox tee -a $play_db
        cat $path/hw_params | Bbox tee -a $play_db
        cat $path/sw_params | Bbox tee -a $play_db
        echo "============================"| Bbox tee -a $play_db
    done
}

function enable_all_debug_log
{
    Bbox echo "1.enable dynamic control"
    for file in `Bbox grep sound /d/dynamic_debug/control | Bbox awk -F ":" '{print $1}'`
    do
        #echo $file
        Bbox echo "file `Bbox basename $file` +p" >/d/dynamic_debug/control
    done
    Bbox echo "2.enable sprd loglevel"
    Bbox echo "0x3" >/proc/asound/sprdphone/asoc-sprd-debug
}

function probe_card_device_info
{
    local i=0
    
    card_count=`cat /proc/asound/card*/id | Bbox wc -l`
    
    Bbox echo "Card count "$card_count

    while (($i<$card_count))
    do
        card_info[$i]=`cat /proc/asound/card$i/id`
        Bbox echo "Card["$i"] name:"${card_info[$i]} | Bbox tee -a $card_db
        Bbox echo -e "\tlist its pcm devices" | Bbox tee -a $card_db
        Bbox cat /proc/asound/pcm | Bbox egrep "0$i-[0-9][0-9].*" | while read line
        do
            Bbox echo -e "\t\t$line" | Bbox tee -a $card_db
        done
        echo "===================================================="       
        if [ -e /proc/device-tree/sound@$i ];then
            Bbox echo -e "\tlist its device-tree" | Bbox tee -a $card_db
            ls /proc/device-tree/sound@$i | Bbox tee -a $card_db
        fi
        echo "===================================================="       
        let i++
    done
}

prepare
enable_all_debug_log
probe_card_device_info
print_playing_status
list_dapm_context
list_codecs_dais_info
list_tinymix_status
list_gpio_info
