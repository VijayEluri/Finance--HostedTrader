#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use Finance::HostedTrader::Config;

my ( $symbols_txt, $tfs_txt );
my $cfg = Finance::HostedTrader::Config->new();

my $result = GetOptions( "symbols=s", \$symbols_txt, "timeframe=s", \$tfs_txt, )
  or die($!);

my $tfs = $cfg->timeframes->all();
$tfs = [ split( ',', $tfs_txt ) ] if ($tfs_txt);
my $symbols = $cfg->symbols->all();
$symbols = [ split( ',', $symbols_txt ) ] if ($symbols_txt);

foreach my $symbol (@$symbols) {
    foreach my $tf (@$tfs) {
        print qq /
CREATE TABLE IF NOT EXISTS `$symbol\_$tf` (
`datetime` DATETIME NOT NULL ,
`open` DECIMAL(9,4) NOT NULL ,
`low` DECIMAL(9,4) NOT NULL ,
`high` DECIMAL(9,4) NOT NULL ,
`close` DECIMAL(9,4) NOT NULL ,
PRIMARY KEY ( `datetime` )
) TYPE = MYISAM ;
/;

    }
}
