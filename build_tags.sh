#!/bin/sh
#vim auto config

srcdir=`ls`

find $srcdir -name "*.h" -o -name "*.c" -o -name "*.cc" -o -name "*.s" -o -name "*.cpp" -o -name "*.java" -o -name "*.mk"  -prune >cscope.files
cscope -bkq -i cscope.files

ctags -R --c++-kinds=+p --fields=+iaS --extra=+q -L cscope.files

echo -e "!_TAG_FILE_SORTED\t2\t/2=foldcase/" > filenametags
find $srcdir -not -regex '.*\.\(png\|gif\)' -type f -printf "%f\t%p\t1\n" | \
    sort -f >> filenametags
