#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 13;
use Test::Exception;
use Data::Dumper;

BEGIN {
use_ok ('Finance::HostedTrader::Trade');
}

my $trade;
throws_ok { 
    $trade = Finance::HostedTrader::Trade->new(
                                                direction => 'short',
                                                openPrice => 1.1,
                                                id => 1.1,
                                                symbol => 'EURUSD',
                                                openDate => '2010-01-01 00:00:00',
    )
} qr/Attribute \(size\) is required/, 'Dies without size attribute';

throws_ok {
    $trade = Finance::HostedTrader::Trade->new(
                                                size => 1000,
                                                openPrice => 1.1,
                                                id => 1.1,
                                                symbol => 'EURUSD',
                                                openDate => '2010-01-01 00:00:00',
    )
} qr/Attribute \(direction\) is required /, 'Dies without direction attribute';

throws_ok {
    $trade = Finance::HostedTrader::Trade->new(
                                                size => 1000,
                                                direction => 'long',
                                                id => 1.1,
                                                symbol => 'EURUSD',
                                                openDate => '2010-01-01 00:00:00',
                                              )
} qr/Attribute \(openPrice\) is required /, 'Dies without openPrice attribute';

throws_ok {
    $trade = Finance::HostedTrader::Trade->new(
                                                size => 1000,
                                                direction => 'long',
                                                openPrice => 1.1,
                                                symbol => 'EURUSD',
                                                openDate => '2010-01-01 00:00:00',
                                              )
} qr/Attribute \(id\) is required /, 'Dies without id attribute';

throws_ok {
    $trade = Finance::HostedTrader::Trade->new(
                                                size => 1000,
                                                direction => 'long',
                                                openPrice => 1.1,
                                                id => 1.1,
                                                openDate => '2010-01-01 00:00:00',
                                              )
} qr/Attribute \(symbol\) is required /, 'Dies without symbol attribute';

throws_ok {
    $trade = Finance::HostedTrader::Trade->new(
                                                size => 1000,
                                                direction => 'long',
                                                openPrice => 1.1,
                                                id => 1.1,
                                                symbol => 'EURUSD',
                                              )
} qr/Attribute \(openDate\) is required /, 'Dies without openDate attribute';

throws_ok {
    $trade = Finance::HostedTrader::Trade->new( size => 1000,
                                                direction => 'short',
                                                openPrice => 1.1,
                                                id => 1.1,
                                                symbol => 'EURUSD',
                                                openDate => '2010-01-01 00:00:00',
                                              )
} qr/Shorts need to be negative numbers /, 'Dies with positive numbers for shorts';

throws_ok {
    $trade = Finance::HostedTrader::Trade->new( size => -1000,
                                                direction => 'long',
                                                openPrice => 1.1,
                                                id => 1.1,
                                                symbol => 'EURUSD',
                                                openDate => '2010-01-01 00:00:00',
                                              )
} qr/Longs need to be positive numbers /, 'Dies with negative numbers for longs';

lives_ok {
    $trade = Finance::HostedTrader::Trade->new( size => 1000,
                                                direction => 'long',
                                                openPrice => 1.1,
                                                id => 1.1,
                                                symbol => 'EURUSD',
                                                openDate => '2010-01-01 00:00:00',
                                              )
} 'Create trade object';
isa_ok($trade, 'Finance::HostedTrader::Trade');

lives_ok {
    $trade = Finance::HostedTrader::Trade->new( size => -1000,
                                                direction => 'short',
                                                openPrice => 1.1,
                                                id => 1.1,
                                                symbol => 'EURUSD',
                                                openDate => '2010-01-01 00:00:00',
                                              )
} 'Create trade object';
isa_ok($trade, 'Finance::HostedTrader::Trade');
