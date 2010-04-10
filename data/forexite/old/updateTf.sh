#!/bin/sh

EXEC_FILE=~/data/tmp.cvtTf.sh
TIMEFRAMES="hour day"



for tf in $TIMEFRAMES; do
./convertTicks2Interval.pl --timeframes=$tf > $EXEC_FILE
chmod u+x $EXEC_FILE
$EXEC_FILE
./loadData.pl $tf
rm *.$tf
done

rm $EXEC_FILE
