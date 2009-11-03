#!/bin/sh

#echo $1

SYMBOLS=`tail -n +2 $1 | cut -d , -f 1 | uniq`
SYMBOLS=`echo $SYMBOLS | perl -ne 'print'`


for symbol in $SYMBOLS; do
grep $symbol $1 | cut -d , -f 2,3,4,5,6,7 | perl -ne 'chomp();($d,$t,$o,$h,$l,$c)=split(",");$d=substr($d,0,4)."-".substr($d,4,2)."-".substr($d,6,2);$t=substr($t,0,2).":".substr($t,2,2).":".substr($t,4,2);print "$d $t,$o,$l,$h,$c\n"' | sort >> $symbol\_60.1min
done
