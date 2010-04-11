#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;
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
