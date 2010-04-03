#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use Finance::HostedTrader::Datasource;

my ($symbols_txt,$tfs_txt);
my $db = Finance::HostedTrader::Datasource->new();

my $result = GetOptions(
		"symbols=s", \$symbols_txt,
		"timeframe=s", \$tfs_txt,
		) or die($!);

my $tfs = $db->getAllTimeframes();
$tfs = [ split(',', $tfs_txt) ] if ($tfs_txt);
my $symbols = $db->getAllSymbols;
$symbols=[split(',', $symbols_txt)] if ($symbols_txt);


foreach my $symbol (@$symbols) {
foreach my $tf (@$tfs) {
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
