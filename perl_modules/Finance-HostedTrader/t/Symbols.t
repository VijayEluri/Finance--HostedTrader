#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 7;
use Test::Exception;
use Data::Dumper;

BEGIN {
use_ok ('Finance::HostedTrader::Config::Symbols');
}

my $empty_tfs = Finance::HostedTrader::Config::Symbols->new(
	'natural' => [],
	'synthetic' => undef,
	);

is_deeply($empty_tfs->natural, [], 'Natural symbols empty');
is_deeply($empty_tfs->synthetic, [], 'Synthetic symbols empty');
is_deeply($empty_tfs->all, [], 'All symbols empty');

my $non_empty_tfs = Finance::HostedTrader::Config::Symbols->new(
	'natural' => [60],
	'synthetic' => [120],
	);

is_deeply($non_empty_tfs->natural, [60], 'Natural symbols non empty');
is_deeply($non_empty_tfs->synthetic, [120], 'Synthetic symbols non empty');
is_deeply($non_empty_tfs->all, [60,120], 'All symbols non empty');
