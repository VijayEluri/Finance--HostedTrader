#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 10;
use Data::Dumper;

BEGIN {
use_ok ('Finance::HostedTrader::System');
}

my $trendfollow = Finance::HostedTrader::System->new( name => 'trendfollow' );
isa_ok($trendfollow,'Finance::HostedTrader::System');
