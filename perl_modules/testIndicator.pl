#!/usr/bin/perl 

use strict;
use warnings;

use Data::Dumper;
use Finance::HostedTrader::ExpressionParser;

my $signal_processor = Finance::HostedTrader::ExpressionParser->new();

my $expr = join( ' ', @ARGV );
my $data = $signal_processor->getIndicatorData(
    { symbol => 'EURUSD', tf => 'day', fields => $expr } );

print Dumper ( \$data );
