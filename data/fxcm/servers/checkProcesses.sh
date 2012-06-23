#!/bin/sh

function checkProcess {
   echo `ps aux | egrep "$1" | grep -vi defunct | grep -v egrep | wc -l`
}

for p in Trader.pl; do
    VAR=$(checkProcess $p)
    if [[ "$VAR" == "0"  ]]; then
        echo Not running $p
    fi
done


#Check there is enough memory
FREEMEM=`free -m | grep Mem | cut -b 36-42`
if [ $FREEMEM -lt 300 ]; then
    echo Running low on memory
    free -m
fi
