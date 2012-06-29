#!/bin/sh
#simple script to export data needed by the tests

set -e

TEST_DATA_DIR=${1:-.}

SYMS="XAGUSD EURUSD USDJPY GBPJPY GBPUSD"
TFS="300 900 3600 7200 14400 86400"

cd "$(dirname "$0")"

rm -fR testdata
mkdir testdata
cd testdata

for sym in $SYMS; do
  for tf in $TFS; do
    mysql -ufxcm -e "SELECT * FROM ${sym}_${tf} WHERE datetime between '2011-01-01 00:00:00' AND '2012-06-28 00:00:00'" fxcm | gzip > ${sym}_${tf}.gz
  done
done

cd ..
tar cPf ${TEST_DATA_DIR}/testdata.tar testdata
rm -fR testdata
