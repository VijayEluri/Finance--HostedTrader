#!/bin/sh
set -e

TIMEFRAME=300
NUM_ITEMS=10
VERBOSE=
CALC_SYNTHETICS_FROM_DATE="15 days ago"

while getopts "d:t:n:v" OPTION
do
    case $OPTION in
        d)
            CALC_SYNTHETICS_FROM_DATE="$OPTARG"
            ;;
        t)
            TIMEFRAME="$OPTARG"
            ;;
        n)
            NUM_ITEMS="$OPTARG"
            ;;
        v)
            VERBOSE=1
            ;;
    esac
done

if [ $VERBOSE ]; then
    echo TF=$TIMEFRAME NUM_ITEMS=$NUM_ITEMS DATE_TO_CALC_SYNTHETICS=$CALC_SYNTHETICS_FROM_DATE
fi

cd $TRADER_HOME/data/fxcm/servers/FXLoadHistoricalData
sleep $(expr $RANDOM % 5 + 5)
./downloadAll.pl $TIMEFRAME $NUM_ITEMS
./load $TIMEFRAME . "$CALC_SYNTHETICS_FROM_DATE"
