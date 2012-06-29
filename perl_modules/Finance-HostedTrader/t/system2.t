#!/usr/bin/perl
# Trade the trendfollow system during a treding period (both open, add and close signals are triggered)
use strict;
use warnings;
use YAML::Tiny;
use File::Basename;

use Finance::HostedTrader::Test::TestSystem;

my $t_path = dirname($0);
my $args;
$args = '--dontSkipDates=1' if ($0 =~ /noskip/);

my $test = Finance::HostedTrader::Test::TestSystem->new(
                systemName	=> 'trendfollow',
                symbols     =>  {
                                    long  => [],
                                    short => [ 'EURUSD' ],
                                },
                resultsFile => "$t_path/trader/trades.xag",
                startDate   => '2012-05-01 00:00:00',
                endDate     => '2012-06-20 00:00:00',
                pathToSystems   => "$t_path/systems",
);

$test->run($args);
