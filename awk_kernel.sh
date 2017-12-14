BEGIN{FS="[=,]";diff_ts_tick=0;diff_apt_ts=0;last_apt=0;last_tick=0;last_fail_apt=0;last_ts=0}
{diff_ts_tick=($4-$2*1000)/1000;diff_apt_ts=($6/1000-$4)/10000}
{if($5=="apt"){
    {if($4-last_ts<0){
        {print "Miss order:line="NR,",ts="$4/1000,",diff="($4-last_ts)/1000,",tick="$2,",diff="$2-last_tick,"ap_diff="(int($6/1000000)-last_fail_apt)/1000 ",diff_diff="$4/1000-$2-(last_ts/1000-last_tick)}
        {last_fail_apt=int($6/1000000)}
    }}
    {diff_diff=$4/1000-$2-(last_ts/1000-last_tick);if((diff_diff>100 && diff_diff<10000)|| (diff_diff<-100 && diff_diff>-100000) )print "diff_diff="diff_diff}
    {last_apt=int($6/1000000);last_tick=$2;last_ts=$4}
}}
