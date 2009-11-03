#!/usr/bin/perl 

use strict;
use warnings;

use Data::Dumper;
use Finance::HostedTrader::ExpressionParser;


my $signal_processor = Finance::HostedTrader::ExpressionParser->new();

my $expr = join(' ', @ARGV);
my $data = $signal_processor->getSignalData( { symbol => 'EURUSD', tf => 'day', expr => $expr } );

print Dumper (\$data);
