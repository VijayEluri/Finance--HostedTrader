#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 10;
use Test::Exception;
use Data::Dumper;

BEGIN {
use_ok ('Finance::HostedTrader::Factory::Account');
}

my $acc;

throws_ok {
    $acc = Finance::HostedTrader::Factory::Account->new(
            SUBCLASS => 'invalidone',
    	)->create_instance();
} qr/Don't know about Account class: invalidone/, 'Factory can\'t instantiate unknown account classes';

$acc = Finance::HostedTrader::Factory::Account->new(
        SUBCLASS    => 'UnitTest',
        startDate   => '2020-06-24 06:00:00',
        endDate     => '2030-06-24 06:00:00',
	)->create_instance();
isa_ok($acc,'Finance::HostedTrader::Account::UnitTest');
is($acc->startDate, '2020-06-24 06:00:00', 'Factory set startDate argument appropriately');
is($acc->endDate, '2030-06-24 06:00:00', 'Factory set endDate argument appropriately');

throws_ok {
    $acc = Finance::HostedTrader::Factory::Account->new(
            SUBCLASS => 'FXCM',
    	)->create_instance();
} qr/Attribute \(address\) is required/, 'FXCM dies without address argument';

throws_ok {
    $acc = Finance::HostedTrader::Factory::Account->new(
            SUBCLASS    => 'FXCM',
            address     => '127.0.0.1',
    	)->create_instance();
} qr/Attribute \(port\) is required/, 'FXCM dies without port argument';

    $acc = Finance::HostedTrader::Factory::Account->new(
            SUBCLASS    => 'FXCM',
            address     => '127.0.0.1',
            port        => '1500',
    	)->create_instance();
isa_ok($acc,'Finance::HostedTrader::Account::FXCM');
is($acc->address, '127.0.0.1', 'Factory set address argument appropriately');
is($acc->port, '1500', 'Factory set port argument appropriately');

