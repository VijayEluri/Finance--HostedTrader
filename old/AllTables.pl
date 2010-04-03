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
	$symbols = $db->getAllSymbols;
} elsif ($symbols_txt eq 'natural') {
	$symbols = $db->getNaturalSymbols;
} elsif ($symbols_txt eq 'synthetics') {
	$symbols = $db->getSyntheticSymbols;
} else {
	$symbols = [split(',',$symbols_txt)] if ($symbols_txt);
}

my $timeframes = $db->getAllTimeframes;
$timeframes = [split(',',$timeframes_txt)] if ($timeframes_txt);


foreach my $symbol (@{$symbols}) {
foreach my $tf (@$timeframes) {
next if ($tf == 60);
#print qq /DELETE FROM `$symbol\_$tf` WHERE datetime > '2009-09-12';
print qq /TRUNCATE TABLE `$symbol\_$tf`;
/;

}
}
