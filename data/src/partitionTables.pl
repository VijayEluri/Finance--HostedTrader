#!/usr/bin/perl -w

use strict;
use Getopt::Long;




my $symbols_txt = 'AUDJPY,AUDNZD,AUDUSD,CADJPY,CHFJPY,EURAUD,EURCAD,EURCHF,EURGBP,EURJPY,EURUSD,GBPCHF,GBPJPY,GBPUSD,NZDJPY,NZDUSD,USDCAD,USDCHF,USDJPY,XAGUSD,XAUUSD,AUDCHF,AUDGBP,AUDCAD,GBPCAD,NZDCAD,NZDCHF,EURNZD,NZDGBP,CADCHF,XAUAUD,XAUCAD,XAUCHF,XAUEUR,XAUGBP,XAUNZD,XAUJPY,XAUXAG,XAGAUD,XAGCAD,XAGCHF,XAGEUR,XAGGBP,XAGNZD,XAGJPY';


my $result = GetOptions("symbols=s", \$symbols_txt);

#Just bother partitionining tables in the per second timeframe
my @tfs= qw (60);
my @symbols=split(',', $symbols_txt);


foreach my $symbol (@symbols) {
foreach my $tf (@tfs) {
print qq /
ALTER TABLE `$symbol\_$tf` 
PARTITION BY HASH(TO_DAYS(datetime)) PARTITIONS 64;
/;

}
}
