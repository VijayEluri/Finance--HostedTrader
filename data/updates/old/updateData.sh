#!/bin/sh

#echo 1. DOWNLOAD DATA
./downloadNow.sh
#echo 2. UNZIPPING DOWNLOADED DAT 
./unzipRecurse.pl ./free_forex_quotes/
#echo CONVERTING NEW DATA INTO DB LOADABLE FORMAT
./getTicks.sh free_forex_quotes
#echo LOADING NEW DATA INTO DB
mysqlimport --local --fields-terminated-by=, -u root fx *.1min
#echo REMOVE SOME TEMPORARY FILES
rm -f *.1min
#echo CREATING SYNTHETIC PAIRS
../synthetics.pl
find ./free_forex_quotes/ -name "*.txt" -exec rm {} \;
#echo MOVE NEWLY DOWNLOADED DATA INTO STORAGE DIRECTORY
mv free_forex_quotes data_done
#find ./free_forex_quotes/ -name "*.zip" -exec mv {} data_done/ \;
#echo UPDATE TIMEFRAMES IN DATABASE
cd ~/data/
./updateTf.sh
#echo CREATE NEW DOWNLOADABLE FILES
./dumpFiles.pl
rm *.csv
mv *.zip ~/download/

