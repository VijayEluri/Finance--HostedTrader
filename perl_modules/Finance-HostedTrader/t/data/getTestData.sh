#!/bin/sh
#simple script to export data needed by the tests

set -e

SYMS="XAGUSD EURUSD USDJPY"
TFS="300 900 3600 7200 14400 86400"

rm -fR testdata
rm -f testdata.tar
mkdir testdata
cd testdata

for sym in $SYMS; do
  for tf in $TFS; do
    mysql -ufxcm -e "SELECT * FROM ${sym}_${tf} WHERE datetime between '2011-10-01 00:00:00' AND '2012-06-25 00:00:00'" fxcm | gzip > ${sym}_${tf}.gz
  done
done

cd ..
tar cPf testdata.tar testdata
rm -fR testdata
