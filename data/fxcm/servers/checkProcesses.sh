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

#Check there is enough memory (current version of Server.exe has a memory leak and needs restarting every now and then)
FREEMEM=`free -m | grep Mem | cut -b 36-42`
if [ $FREEMEM -lt 350 ]; then
    echo Running low on memory
    free -m
fi

# check there are enough records in the databse to process systems properly
# this is necessary because the mysql fxcm database is memory only.
# mysql restarts will wipe it out.
# (there is a different process which checks if data is up to date)
#TODO instead of hard coding this to a defined number of records on a specific symbol
# load a System, then check it's  symbols and maxLoadedItems in the various sections
DATA_RECORDS=`mysql -N -ufxcm -e "select count(1) from EURUSD_900" fxcm`
if [ $DATA_RECORDS -lt 1900 ]; then
    echo There don\'t seem to be enough data records in the fxcm database
fi
