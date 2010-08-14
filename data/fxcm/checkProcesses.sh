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
