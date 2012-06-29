#!/usr/bin/perl
# Trade the trendfollow system during a choppy period (only open and close signals are triggered, no trades are added on to)
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
                                    short => [ 'USDJPY' ],
                                },
                resultsFile => "$t_path/trader/trades.jpy",
                startDate   => '2012-03-05 06:00:00',
                endDate     => '2012-03-14 00:00:00',
                pathToSystems   => "$t_path/systems",
);

$test->run($args);
