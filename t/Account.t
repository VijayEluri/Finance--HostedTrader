#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;
use Data::Dumper;

BEGIN {
use_ok ('Finance::HostedTrader::Account');
}

my $db = Finance::HostedTrader::Account->new(
        username => 'not implemented',
        password => 'not implemented',
	);
isa_ok($db,'Finance::HostedTrader::Account');

