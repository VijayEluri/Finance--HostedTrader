#!/usr/bin/perl -w

use strict;
use Getopt::Long;


my $symbols_txt = 'AUDJPY,AUDNZD,AUDUSD,CADJPY,CHFJPY,EURAUD,EURCAD,EURCHF,EURGBP,EURJPY,EURUSD,GBPCHF,GBPJPY,GBPUSD,NZDJPY,NZDUSD,USDCAD,USDCHF,USDJPY,XAGUSD,XAUUSD,AUDCHF,AUDGBP,AUDCAD,GBPCAD,NZDCAD,NZDCHF,EURNZD,NZDGBP,CADCHF,XAUAUD,XAUCAD,XAUCHF,XAUEUR,XAUGBP,XAUNZD,XAUJPY,XAUXAG,XAGAUD,XAGCAD,XAGCHF,XAGEUR,XAGGBP,XAGNZD,XAGJPY';
my $tfs_txt = '60,3600,7200,10800,14400,86400,604800';

my $result = GetOptions(
		"symbols=s", \$symbols_txt,
		"timeframe=s", \$tfs_txt,
		) or die($!);


my @tfs= split(',', $tfs_txt);
my @symbols=split(',', $symbols_txt);


foreach my $symbol (@symbols) {
foreach my $tf (@tfs) {
print qq /
CREATE TABLE IF NOT EXISTS `$symbol\_$tf` (
`datetime` DATETIME NOT NULL ,
`open` FLOAT NOT NULL ,
`low` FLOAT NOT NULL ,
`high` FLOAT NOT NULL ,
`close` FLOAT NOT NULL ,
PRIMARY KEY ( `datetime` )
) TYPE = MYISAM ;
/;

}
}
