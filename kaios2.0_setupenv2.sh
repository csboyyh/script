#!/bin/bash 

TMP_IOT_DIR="/tmp/iot-"$USER
SR_CC="/usr/bin/gcc-4.8"
SR_PP="/usr/bin/g++-4.8"
DT_CC=${TMP_IOT_DIR}"/gcc"
DT_PP=${TMP_IOT_DIR}"/g++"

if [ ! -d ${TMP_IOT_DIR} ]; then
        mkdir ${TMP_IOT_DIR}
    else
            rm ${TMP_IOT_DIR} -r
                mkdir ${TMP_IOT_DIR}
            fi

ln -s ${SR_CC} ${DT_CC}
ln -s ${SR_PP} ${DT_PP}
export PATH=${TMP_IOT_DIR}:$PATH

