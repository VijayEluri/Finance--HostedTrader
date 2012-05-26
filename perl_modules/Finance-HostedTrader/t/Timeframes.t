#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 12;
use Test::Exception;
use Data::Dumper;

BEGIN {
use_ok ('Finance::HostedTrader::Config::Timeframes');
}

my $empty_tfs = Finance::HostedTrader::Config::Timeframes->new(
	'natural' => [],
	'synthetic' => undef,
	);

is_deeply($empty_tfs->natural, [], 'Natural timeframes empty');
is_deeply($empty_tfs->synthetic, [], 'Synthetic timeframes empty');
is_deeply($empty_tfs->all, [], 'All timeframes empty');

my $tfs = Finance::HostedTrader::Config::Timeframes->new(
	'natural' => [ qw (300 60) ], #Make sure timeframes are unordered to test if the module returns them ordered
	'synthetic' => [ qw (7200 120) ], #Make sure timeframes are unordered to test if the module returns them ordered
	);
isa_ok($tfs,'Finance::HostedTrader::Config::Timeframes');
is($tfs->getTimeframeName($tfs->getTimeframeID('min')), 'min', 'GetTimeframe{ID,Name}');
is_deeply($tfs->natural, [60, 300], 'Natural timeframes sorted');
is_deeply($tfs->synthetic, [120, 7200], 'Synthetic timeframes sorted');
is_deeply($tfs->all, [60, 120, 300, 7200], 'All timeframes sorted');


$tfs = Finance::HostedTrader::Config::Timeframes->new(
	'natural' => [ qw (300 60) ],
	);
isa_ok($tfs,'Finance::HostedTrader::Config::Timeframes');
is_deeply($tfs->synthetic, [], 'Synthetic timeframes empty but defined');


throws_ok {Finance::HostedTrader::Config::Timeframes->new()} qr /Attribute \(natural\) is required/, 'natural timeframes required';

