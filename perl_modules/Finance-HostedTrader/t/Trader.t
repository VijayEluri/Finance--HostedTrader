#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 6;
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
my $account = Finance::HostedTrader::Factory::Account->new( SUBCLASS => 'UnitTest', system => $trendfollow, startDate=> '2011-10-13' )->create_instance();
my $trader = Finance::HostedTrader::Trader->new( system => $trendfollow, account => $account );
isa_ok($trader, 'Finance::HostedTrader::Trader');

is($trader->getEntryValue('EURUSD', 'long'), 1.3768, 'getEntryValue');
is($trader->getEntryValue('EURUSD', 'short'), 1.3763, 'getExitValue');

is($trader->getExitValue('EURUSD', 'long'), 1.3153, 'getEntryValue');
is($trader->getExitValue('EURUSD', 'short'), 1.3819, 'getExitValue');
