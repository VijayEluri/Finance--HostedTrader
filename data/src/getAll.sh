#!/bin/sh

wget -o output -c -r -l 1 --limit-rate=150k -w 1 --random-wait -nH -A zip -np http://www.forexite.com/free_forex_quotes/forex_history_arhiv.html
