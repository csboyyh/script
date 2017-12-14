BEGIN {FS="[:,=.\[]";pt1=0;elt=0;eut=0;i=1;cu=0;cl=0}
{
    {if(index($1,"time")!=0){{pt1=$5;elt=$9;eut=$11;i++}
    {if(pt1>eut){print "Err "i":("pt1")Over Upper "pt1-eut"ms postion "substr($0,index($0,"Name"),100);cu++}}
    {if(pt1<elt){print "Err "i":("pt1")Under Lower "elt-pt1"ms postion "substr($0,index($0,"Name"),100);cl++}}
    }}
}
END{print "Sum over="cu" lower="cl}
