#/bin/bash

for file in `grep 9850j --exclude-dir=".git" -ri . | awk -F ':' '{print $1}'`
do
    echo "modify file:$file"
    sed -i "s/9850j/9850kh/g" $file
    sed -i "s/9850J/9850KH/g" $file
done

find . -type d -name "*9850j*" -exec rename -v 's/9850j/9850kh/g' {} \;

find . -type f -name "*9850j*" -exec rename -v 's/9850j/9850kh/g' {} \;

