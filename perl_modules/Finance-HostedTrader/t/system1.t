#!/usr/bin/perl

use strict;
use warnings;
use YAML::Tiny;

use Finance::HostedTrader::Test::TestSystem;

my $args;
$args = '--dontSkipDates' if ($0 =~ /noskip/);

my $test = TestSystem->new(
                systemName	=> 'trendfollow',
                symbols     =>  {
                                    long  => [],
                                    short => [ 'USDJPY' ],
                                },
                resultsFile => 'trader/trades.jpy',
                startDate   => '2010-08-18 06:00:00',
                endDate     => '2010-09-17 00:00:00',
);

$test->run($args);
