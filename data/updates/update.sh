#!/bin/sh

ERROR_FILE=/tmp/fx.errors.log

function die_if_error {
if [ $? -ne 0 ]; then
exit
fi
}

if [ ! -f LAST_DOWNLOADED ]; then
echo "Don't know what to download"
exit
fi

cat LAST_DOWNLOADED | ./missingDates.pl > TO_DOWNLOAD
die_if_error
wget -q -N -i TO_DOWNLOAD -nH -c -r -l 1 -np -A.zip
die_if_error

find free_forex_quotes -name "*.zip" -exec unzip -q -o "{}" \;
die_if_error

find ./ -name "*.txt" -exec ./process.forexite.sh "{}" \;
die_if_error

mysqlimport --local --fields-terminated-by=, --lines-terminated-by='\r\n' -s -u root fx *.1min
die_if_error

rm -Rf *.txt *.1min free_forex_quotes

~/fx/synthetics.pl
die_if_error
~/fx/updateTf.pl --start="4 days ago at midnight"
die_if_error
~/fx/TruncateWeekly.pl | mysql -u root fx
die_if_error
~/fx/updateTf.pl --timeframe=604800 --available-timeframe=day
die_if_error
~/fx/dumpFiles.pl
die_if_error

mv TO_DOWNLOAD LAST_DOWNLOADED
die_if_error
