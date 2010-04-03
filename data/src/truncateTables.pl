#!/usr/bin/perl -w

use strict;
use Getopt::Long;

my $symbols_txt =
'AUDJPY,AUDNZD,AUDUSD,CADJPY,CHFJPY,EURAUD,EURCAD,EURCHF,EURGBP,EURJPY,EURUSD,GBPCHF,GBPJPY,GBPUSD,NZDJPY,NZDUSD,USDCAD,USDCHF,USDJPY,XAGUSD,XAUUSD';

my $result = GetOptions( "symbols=s", \$symbols_txt );

my @tfs = qw (3600 86400);
my @symbols = split( ',', $symbols_txt );

foreach my $symbol (@symbols) {
    foreach my $tf (@tfs) {
        print qq /
TRUNCATE TABLE `$symbol\_$tf`;
/;

    }
}
