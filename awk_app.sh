BEGIN{FS="[:.]";i=0}
{
    {if(a[$1]==0){b[i]=$1;a[$1]=$1;i++}else count[$1]++}
}
END{for(x in a){print "count="count[x] ",reason="a[x]}}
