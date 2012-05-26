#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 8;
use Test::Exception;
use Data::Dumper;

BEGIN {
use_ok ('Finance::HostedTrader::Factory::Notifier');
}

my $acc;

throws_ok {
    $acc = Finance::HostedTrader::Factory::Notifier->new(
            SUBCLASS => 'invalidone',
    	)->create_instance();
} qr/Don't know about Notifier class: invalidone/, 'Factory can\'t instantiate unknown account classes';


throws_ok {
    $acc = Finance::HostedTrader::Factory::Notifier->new(
            SUBCLASS => 'UnitTest',
    	)->create_instance();
} qr/Attribute \(expectedTradesFile\) is required/, 'UnitTest dies without expectedTradesFile argument';

throws_ok {
    $acc = Finance::HostedTrader::Factory::Notifier->new(
            SUBCLASS => 'UnitTest',
            expectedTradesFile => 'non existant file',
    	)->create_instance();
} qr/file "non existant file" does not exist/, 'UnitTest dies with bad expectedTradesFile argument';

$acc = Finance::HostedTrader::Factory::Notifier->new(
        SUBCLASS    => 'UnitTest',
        expectedTradesFile => undef,
	)->create_instance();
isa_ok($acc,'Finance::HostedTrader::Trader::Notifier::UnitTest');
can_ok($acc, qw/open close/);

    $acc = Finance::HostedTrader::Factory::Notifier->new(
            SUBCLASS    => 'Production',
    	)->create_instance();
isa_ok($acc,'Finance::HostedTrader::Trader::Notifier::Production');
can_ok($acc, qw/open close/);

