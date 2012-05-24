#!/bin/sh



#Check there is enough memory
FREEMEM=`free -m | grep Mem | cut -b 36-42`
if [ $FREEMEM -lt 300 ]; then
    echo Running low on memory
    free -m
fi
