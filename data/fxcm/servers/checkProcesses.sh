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


#check if the FXCM API server is responding to requests
RES=`echo ask XAU/USD | nc -w 10 localhost 1500`
if [[ "$RES" = "" ]]; then
    echo Server timeout
else
    if [[ "${RES:0:4}" != "200 " ]]; then
        echo Server returned bad response "$RES"
    fi
fi
