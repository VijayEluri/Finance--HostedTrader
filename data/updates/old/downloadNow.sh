#!/bin/sh


#-i TO_DOWNLOAD downloads URLS from file TO_DOWNLOAD
#-b background
#-nH do not create host directory (ratedata.gaincapital.com)
#-c resume downloading
#-r recursive downloads
#-l 2 recurse two levels
#-np do not ascend to parent directories
#-R do not download files with these extensions


./missingDates.pl > TO_DOWNLOAD.tmp
mv TO_DOWNLOAD.tmp TO_DOWNLOAD
wget -q -N -i TO_DOWNLOAD -nH -c -r -l 1 -np -A.zip
