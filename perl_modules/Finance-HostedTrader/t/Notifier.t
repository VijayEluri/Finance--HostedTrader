#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 8;
use Test::Exception;
use Data::Dumper;

BEGIN {
use_ok ('Finance::HostedTrader::Trader::Notifier');
}


my $notifier = Finance::HostedTrader::Trader::Notifier->new();

isa_ok($notifier,'Finance::HostedTrader::Trader::Notifier');


can_ok($notifier, qw/open close/);

throws_ok { $notifier->open( stopLoss => 'abc', symbol => 'EURUSD', direction => 'long', amount => 10, now => '', balance => 10, nav => 10 ) } qr/The 'stopLoss' parameter \("abc"\)/, "Current value cannot non numeric";
throws_ok { $notifier->open( stopLoss => '-1', symbol => 'EURUSD', direction => 'long', amount => 10, now => '', balance => 10, nav => 10 ) } qr/The 'stopLoss' parameter \("-1"\)/, "Current value cannot be negative";
throws_ok { $notifier->open( stopLoss => '1', symbol => 'EURUSD', direction => 'badvalue', amount => 10, now => '', balance => 10, nav => 10 ) } qr/The 'direction' parameter \("badvalue"\)/, "direction can only be long/short";
throws_ok { $notifier->open( stopLoss => '1', symbol => 'EURUSD', direction => 'short', amount => 10, now => '', balance => 10, nav => 10 ) } qr/overrideme/, "open must be implemented by child class";
throws_ok { $notifier->close( currentValue => '1', symbol => 'EURUSD', direction => 'long', amount => 10, now => '', balance => 10, nav => 10 ) } qr/overrideme/, "close must be implemented by child class";

