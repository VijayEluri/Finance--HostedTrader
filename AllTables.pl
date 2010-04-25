#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use Finance::HostedTrader::Datasource;
use Data::Dumper;

my ($timeframes_txt, $symbols_txt);

my $result = GetOptions(
                        "timeframes=s", \$timeframes_txt,
                        "symbols=s", \$symbols_txt,
					);

my $db = Finance::HostedTrader::Datasource->new();

my $symbols;
if (!defined($symbols_txt)) {
	$symbols = $db->cfg->symbols->all;
} elsif ($symbols_txt eq 'natural') {
	$symbols = $db->cfg->symbols->natural;
} elsif ($symbols_txt eq 'synthetics') {
	$symbols = $db->cfg->symbols->synthetic;
} else {
	$symbols = [split(',',$symbols_txt)] if ($symbols_txt);
}

my $timeframes = $db->cfg->timeframes->all;
$timeframes = [split(',',$timeframes_txt)] if ($timeframes_txt);


foreach my $symbol (@{$symbols}) {
foreach my $tf (@$timeframes) {
next if ($tf == 60);
#print qq /DELETE FROM `$symbol\_$tf` WHERE datetime > '2009-09-12';
print qq /ALTER TABLE `$symbol\_$tf` MODIFY open DECIMAL(9,4) NOT NULL, MODIFY low DECIMAL(9,4) NOT NULL, MODIFY high DECIMAL(9,4) NOT NULL, MODIFY close DECIMAL(9,4) NOT NULL;
/;

}
}
