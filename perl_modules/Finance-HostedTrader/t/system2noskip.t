#!/usr/bin/perl

use strict;
use warnings;
use YAML::Tiny;

use TestSystem;

my $args;
$args = '--dontSkipDates' if ($0 =~ /noskip/);

my $test = TestSystem->new(
                systemName	=> 'trendfollow',
                symbols     =>  {
                                    long  => [ 'XAGUSD' ],
                                    short => [],
                                },
                resultsFile => 'trader/trades.xag',
                startDate   => '2010-08-18 06:00:00',
                endDate     => '2010-10-17 00:00:00',
);

$test->run($args);