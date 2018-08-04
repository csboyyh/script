#/bin/bash

echo "===uncompress gz log files==="

find . -name *.gz -exec gzip -d {} \;

echo "===find out test result as below==="

find . -name test_result.xml | xargs grep $1

echo "===find out the failed reason==="

for file in `find . -name "host_log*" |xargs grep -l -e ".*testFailed.*$1"`
do
    echo "===search file:"$file"==="
    grep  ".*ModuleListener.testFailed.*$1" -A 5 -h -i $file
    time=`grep  ".*ModuleListener.testFailed.*$1" -A 5 -h -i $file | awk '{print $1,$2}'|head -n 1`    
    echo "===print out device log==="$time
    grep "$time" -ni $(dirname $file)/device*
    find . -name "*.log" |xargs grep "$time" -n
    
done

