#!/bin/sh

function die_if_error {
if [ $? -ne 0 ]; then
exit 1
fi
}

#RatePrinter will write data in the $1 timeframe to individual files
#The other two arguments are the login details to the API account
wine ./RatePrinter.exe FX1125841001 3151 $1 2> /dev/null
die_if_error
