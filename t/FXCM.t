#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 20;
use Test::Exception;
use Data::Dumper;

use Test::MockModule;

BEGIN {
use_ok ('Finance::HostedTrader::Factory::Account');
}
 
my $mock = new Test::MockModule('Finance::HostedTrader::Account::FXCM');

my $acc;
my $mock_result;

    $acc = Finance::HostedTrader::Factory::Account->new(
            SUBCLASS    => 'FXCM',
            address     => '127.0.0.1',
            port        => '1501',
            notifier    => undef,
    )->create_instance();

    isa_ok($acc,'Finance::HostedTrader::Account::FXCM');

    $mock->mock('_sendCmd', sub {
        my ($self, $cmd) = @_;

        is($cmd, 'trades', 'trades command in refreshPositions');
        return '';
    });
    $acc->refreshPositions();

    $mock->mock('_sendCmd', sub {
        my ($self, $cmd) = @_;

        return "-\n  -\n -\n";
    });
    throws_ok { $acc->refreshPositions() } qr/syntax error/, 'Invalid yaml returned from server';


    $mock->mock('_sendCmd', sub {
        my ($self, $cmd) = @_;

        is($cmd, 'trades', 'trades command');
        return "- symbol: AUDJPY
  id: 6417812
  direction: long
  openPrice: 85.609
  size: 60000
  openDate: 2011-05-06 00:20:26
  pl: 101.75
- symbol: AUDJPY
  id: 6417813
  direction: long
  openPrice: 85.679
  size: 10000
  openDate: 2011-05-06 00:40:26
  pl: 16.94
- symbol: USDJPY
  id: 6378125
  direction: short
  openPrice: 80.563
  size: 60000
  openDate: 2011-05-09 16:55:11
  pl: -275.923
";
    });

    my $position = $acc->getPosition('USDJPY');
    is($position->size, -60000, 'shorts are converted to negative size');
    $position = $acc->getPosition('AUDJPY');
    is($position->size, 70000, 'handles multiple trades in a position');

    $mock->mock('_sendCmd', sub {
        my ($self, $cmd) = @_;

        is($cmd, 'ask EUR/USD', 'Symbol converted in ask command');
    });

    $acc->getAsk('EURUSD');

    throws_ok {$acc->getAsk('rubbish') } qr/Unsupported symbol/, 'Unsupported symbol';

    $mock->mock('_sendCmd', sub {
        my ($self, $cmd) = @_;

        is($cmd, 'bid EUR/USD', 'Symbol converted in bid command');
    });

    $acc->getBid('EURUSD');

    $mock->mock('_sendCmd', sub {
        my ($self, $cmd) = @_;

        if ($cmd eq 'openmarket EUR/USD long 10000') {
            return "16009151 1.4231"
        } elsif ($cmd eq 'trades') {
            return "- symbol: EURUSD
  id: 16009151
  direction: long
  openPrice: 1.4231
  size: 10000
  openDate: 2011-05-09 16:55:11
  pl: -2.00
";
        } else {
            die('unexpected command');
        }
    });
    $acc->openMarket('EURUSD', 'long', '10000', '1.3000');
    $position = $acc->getPosition('EURUSD');
    is($position->size, 10000, 'new position opened');
    is($position->averagePrice, 1.4231, 'new position opened');

    $mock->mock('_sendCmd', sub {
        my ($self, $cmd) = @_;

        is($cmd, 'closemarket 123 10000', 'closemarket command');
    });
    $acc->closeMarket(123, 10000);

    $mock->mock('_sendCmd', sub {
        my ($self, $cmd) = @_;

        is($cmd, 'baseunit AUD/USD', 'Symbol converted in baseunit command');
    });
    $acc->getBaseUnit('AUDUSD');

    $mock->mock('_sendCmd', sub {
        my ($self, $cmd) = @_;

        is($cmd, 'nav', 'nav command');
    });
    $acc->getNav();

    is($acc->getBaseCurrency(), 'GBP', 'getBaseCurrency');

    my $epoch = $acc->getServerEpoch();
    like($epoch, qr/^\d+$/, 'Epoch is numeric');
    ok($epoch > 0, 'Epoch is > 0');

    like($acc->getServerDateTime(), qr/^[12][0-9]{3}-[01][0-9]-[0-3][0-9] [0-2][0-9]:[0-5][0-9]:[0-5][0-9]$/, 'DateTime format');
