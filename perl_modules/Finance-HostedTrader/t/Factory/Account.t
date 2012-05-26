#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 13;
use Test::Exception;
use Data::Dumper;
use File::Basename;

use Finance::HostedTrader::System;

BEGIN {
use_ok ('Finance::HostedTrader::Factory::Account');
}

my $t_path = dirname($0);

my $acc;

throws_ok {
    $acc = Finance::HostedTrader::Factory::Account->new(
            SUBCLASS => 'invalidone',
    	)->create_instance();
} qr/Don't know about Account class: invalidone/, 'Factory can\'t instantiate unknown account classes';


throws_ok {
    $acc = Finance::HostedTrader::Factory::Account->new(
            SUBCLASS => 'UnitTest',
    	)->create_instance();
} qr/Attribute \(system\) is required/, 'UnitTest dies without system argument';

my $trendfollow = Finance::HostedTrader::System->new( name => 'trendfollow', pathToSystems => $t_path );

$acc = Finance::HostedTrader::Factory::Account->new(
        SUBCLASS    => 'UnitTest',
        system      => $trendfollow,
        startDate   => '2020-06-24 06:00:00',
        endDate     => '2030-06-24 06:00:00',
	)->create_instance();
isa_ok($acc,'Finance::HostedTrader::Account::UnitTest');
can_ok($acc, qw/refreshPositions getAsk getBid openMarket closeMarket getBaseUnit getNav balance getBaseCurrency checkSignal getIndicatorValue waitForNextTrade convertBaseUnit getPosition getPositions closeTrades pl getServerEpoch getSymbolBase/);
is($acc->startDate, '2020-06-24 06:00:00', 'Factory set startDate argument appropriately');
is($acc->endDate, '2030-06-24 06:00:00', 'Factory set endDate argument appropriately');

throws_ok {
    $acc = Finance::HostedTrader::Factory::Account->new(
            SUBCLASS    => 'ForexConnect',
            password    => 'password',
    	)->create_instance();
} qr/Attribute \(username\) is required/, 'ForexConnect dies without username argument';

throws_ok {
    $acc = Finance::HostedTrader::Factory::Account->new(
            SUBCLASS    => 'ForexConnect',
            username    => 'username',
    	)->create_instance();
} qr/Attribute \(password\) is required/, 'ForexConnect dies without password argument';

    $acc = Finance::HostedTrader::Factory::Account->new(
            SUBCLASS    => 'ForexConnect',
            username    => 'username',
            password    => 'password',
            accountType => 'Demo',
    	)->create_instance();
isa_ok($acc,'Finance::HostedTrader::Account::FXCM::ForexConnect');
can_ok($acc, qw/refreshPositions getAsk getBid openMarket closeMarket getBaseUnit getNav balance getBaseCurrency checkSignal getIndicatorValue waitForNextTrade convertBaseUnit getPosition getPositions closeTrades pl getServerEpoch getSymbolBase/);
is($acc->username, 'username', 'Factory set username argument appropriately');
is($acc->password, 'password', 'Factory set password argument appropriately');

