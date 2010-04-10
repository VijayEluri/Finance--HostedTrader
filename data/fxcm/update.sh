#!/bin/sh

function die_if_error {
if [ $? -ne 0 ]; then
exit 1
fi
}

wine ./RatePrinter.exe 2> /dev/null
die_if_error

echo Success
