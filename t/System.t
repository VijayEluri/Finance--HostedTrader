#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;
use Data::Dumper;
use File::Basename;

my $t_path = dirname($0);

BEGIN {
use_ok ('Finance::HostedTrader::System');
}

my $trendfollow = Finance::HostedTrader::System->new( name => 'trendfollow', pathToSystems => "$t_path/systems" );
isa_ok($trendfollow,'Finance::HostedTrader::System');
