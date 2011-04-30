#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 20;
use Test::Exception;
use Data::Dumper;

BEGIN {
use_ok ('Finance::HostedTrader::Account');
}

my $acc;

throws_ok {
    $acc = Finance::HostedTrader::Account->new(
            startDate => 'invalid',
    	);
} qr /Invalid date format: invalid/, 'Dies with invalid start date';

throws_ok {
    $acc = Finance::HostedTrader::Account->new(
            endDate => 'invalid',
    	);
} qr /Invalid date format: invalid/, 'Dies with invalid end date';

throws_ok {
    $acc = Finance::HostedTrader::Account->new(
            startDate   => '9999-01-01 00:00:00',
            endDate     => '0001-01-01 00:00:00',
    	);
} qr /End date cannot be earlier than start date/, 'Dies with end date smaller than start date';

    $acc = Finance::HostedTrader::Account->new(
            startDate     => '0001-01-01 00:00:00',
            endDate   => '9999-01-01 00:00:00',
    	);

isa_ok($acc,'Finance::HostedTrader::Account');

is($acc->startDate, '0001-01-01 00:00:00', 'start date defined');
is($acc->endDate, '9999-01-01 00:00:00', 'end date defined');

can_ok($acc, qw/refreshPositions getAsk getBid openMarket closeMarket getBaseUnit getNav balance getBaseCurrency checkSignal getIndicatorValue waitForNextTrade convertToBaseCurrency convertBaseUnit getPosition getPositions closeTrades pl getServerEpoch getSymbolBase/);

foreach my $method (qw/refreshPositions getBid getAsk openMarket closeMarket getBaseUnit getNav getBaseCurrency getServerEpoch/) {
throws_ok { $acc->$method } qr/overrideme/, "$method must be implemented by child class";
}

throws_ok { $acc->getSymbolBase('invalid') } qr/Unsupported symbol 'invalid'/, 'Unsupported symbol';
is($acc->getSymbolBase('EURUSD'), 'USD', 'base for EURUSD is USD');
is($acc->getSymbolBase('GBPCHF'), 'CHF', 'base for GBPCHF is CHF');
