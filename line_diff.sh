#/bin/bash

last_value=-1

for line in `cat $1`
do
    if [ $last_value -ne -1 ]
    then
        echo "diff:"`expr $line - $last_value`>>$2
    fi
    last_value=$line;
done
cat $2 | uniq -u | sort
