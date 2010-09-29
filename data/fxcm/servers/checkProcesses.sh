#!/bin/sh



function checkProcess {
   echo `ps aux | egrep "$1" | grep -vi defunct | grep -v egrep | wc -l`
}

for p in Trader.pl RatePrinter.exe Server.exe; do
    VAR=$(checkProcess $p)
    if [[ "$VAR" == "0"  ]]; then
        echo Not running $p
    fi
done


#check if data is up to date
LAST_TICK=`mysql -N -ufxcm -e "SELECT MAX(datetime) FROM AUDUSD_300" fxcm`
perl -MDate::Manip -e 'my $timediff=Delta_Format(DateCalc($ARGV[0], "now"),0,"%sh"); print "Datafeed out of date\n" if ($timediff > 1200)' "$LAST_TICK" 

#check if the FXCM API server is responding to requests
RES=`echo ask XAUUSD | nc -w 10 localhost 1500`
if [[ "$RES" = "" ]]; then
    echo Server timeout
else
    if [[ "${RES:0:4}" != "200 " ]]; then
        echo Server returned bad response "$RES"
    fi
fi
