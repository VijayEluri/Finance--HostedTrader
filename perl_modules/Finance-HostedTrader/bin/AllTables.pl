#!/usr/bin/perl
package Finance::HostedTrader;
# ABSTRACT: Generates SQL statments which can be used against all symbols/timeframes

use strict;
use warnings;
use Getopt::Long;
use Finance::HostedTrader::Datasource;
use Data::Dumper;

my ($sql,$timeframes_txt, $symbols_txt) = ('TABLE_NAME');

my $result = GetOptions(
                        "timeframes=s", \$timeframes_txt,
                        "symbols=s", \$symbols_txt,
                        "sql=s", \$sql,
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
my $tableName = $symbol.'_'.$tf;
my $s = $sql;
$s =~ s/TABLE_NAME/$tableName/g;
print $s,"\n";
}
}
