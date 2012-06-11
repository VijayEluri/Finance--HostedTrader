#!/bin/sh
set -e
source $TRADER_HOME/setupEnv.source

FXCM_TIMEFRAME=m5
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
            FXCM_TIMEFRAME="$OPTARG"
            ;;
        n)
            NUM_ITEMS="$OPTARG"
            ;;
        v)
            VERBOSE=1
            ;;
    esac
done

case $FXCM_TIMEFRAME in
    m5)
        TIMEFRAME=300
        ;;
    H1)
        TIMEFRAME=3600
        ;;
    D1)
        TIMEFRAME=86400
        ;;
    W1)
        TIMEFRAME=604800
        ;;
    *)
        echo Unknown FXCM timeframe: $FXCM_TIMEFRAME
        ;;
esac

if [ $VERBOSE ]; then
    echo FXCM_TF=$FXCM_TIMEFRAME TF=$TIMEFRAME NUM_ITEMS=$NUM_ITEMS DATE_TO_CALC_SYNTHETICS=$CALC_SYNTHETICS_FROM_DATE
fi

. $TRADER_HOME/data/fxcm/servers/config_demo.sh
cd $TRADER_HOME/data/fxcm/servers/FXLoadHistoricalData
SYMBOLS=`perl -MFinance::HostedTrader::Config -e 'print join(" ", map {substr($_,0,3)."/".substr($_,3)} @{Finance::HostedTrader::Config->new()->symbols->all})'`
sleep $(expr $RANDOM % 5 + 5)
set +e
#java org.zonalivre.FXConnect.DownloadAll $FXCM_USER $FXCM_PASSWORD $FXCM_TYPE $FXCM_TIMEFRAME $NUM_ITEMS $SYMBOLS
./downloadAll.pl $FXCM_USER $FXCM_PASSWORD $FXCM_TYPE $FXCM_TIMEFRAME $NUM_ITEMS $SYMBOLS
set -e
./load $TIMEFRAME . "$CALC_SYNTHETICS_FROM_DATE"
