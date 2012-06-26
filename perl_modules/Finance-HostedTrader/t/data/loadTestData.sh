#!/bin/sh
#simple script to import data needed by the tests

set -e

rm -fR testdata
tar xf testdata.tar
cd testdata

for file in *gz; do
    gunzip $file
done

mysqlimport --ignore --ignore-lines=1 --local --fields-terminated-by='\t' --lines-terminated-by='\n' -s -ufxcm fxcm *_*
cd ..
rm -fR testdata
