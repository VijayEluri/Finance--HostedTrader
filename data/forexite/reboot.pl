#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use Finance::HostedTrader::Config;
use Data::Dumper;



my $cfg = Finance::HostedTrader::Config->new();


doAll($cfg->symbols->synthetic, $cfg->timeframes->all);
doAll($cfg->symbols->all, $cfg->timeframes->synthetic);

sub doAll {
my ($symbols, $timeframes) = @_;
foreach my $symbol ( @{$symbols} ) {
    foreach my $tf ( @{$timeframes} ) {
        print qq /TRUNCATE TABLE `$symbol\_$tf`;
/;
    }
}
}

=pod
updateTf.pl --verbose --available-timeframe=min --timeframes=300
updateTf.pl --verbose --available-timeframe=5min --timeframes=900,1800,3600
updateTf.pl --verbose --available-timeframe=hour --timeframes=7200,14400,86400
updateTf.pl --verbose --available-timeframe=day --timeframes=604800
=cut
