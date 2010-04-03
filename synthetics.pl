#!/usr/bin/perl 

use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;
use Finance::HostedTrader::Datasource;

my ($timeframe,$verbose) = (60);

my $db = Finance::HostedTrader::Datasource->new();
my $synthetics = $db->getSyntheticSymbols;

my $symbols_txt;
my $result = GetOptions(
                        "symbols=s", \$symbols_txt,
                        "timeframe=i", \$timeframe,
                        "verbose", \$verbose
                        );
$synthetics = [ split(',', $symbols_txt) ] if ($symbols_txt);

foreach my $synthetic (@$synthetics) {
print "$synthetic [$timeframe]" if ($verbose);
$db->createSynthetic($synthetic,$timeframe);
}
