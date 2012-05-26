#!/usr/bin/perl

use strict;
use warnings;
use Test::More skip_all => 'Flaky'; #tests => 6;
use Test::Exception;
use Data::Dumper;
use File::Basename;

BEGIN {
use_ok ('Finance::HostedTrader::Trader');
}
use Finance::HostedTrader::System;
use Finance::HostedTrader::Factory::Account;

my $t_path = dirname($0);

my $trendfollow = Finance::HostedTrader::System->new( name => 'trendfollow', pathToSystems => "$t_path/systems" );
my $account = Finance::HostedTrader::Factory::Account->new( SUBCLASS => 'UnitTest', system => $trendfollow, startDate=> '2005-01-01' )->create_instance();
my $trader = Finance::HostedTrader::Trader->new( system => $trendfollow, account => $account );
isa_ok($trader, 'Finance::HostedTrader::Trader');

is($trader->getEntryValue('EURUSD', 'long'), 1.3618, 'getEntryValue');
is($trader->getEntryValue('EURUSD', 'short'), 1.3578, 'getExitValue');

is($trader->getExitValue('EURUSD', 'long'), 1.3139, 'getEntryValue');
is($trader->getExitValue('EURUSD', 'short'), 1.3663, 'getExitValue');
