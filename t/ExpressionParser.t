#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 6;
use Test::Exception;
use Data::Dumper;

BEGIN {
use_ok ('Finance::HostedTrader::ExpressionParser');
}

my $expr = Finance::HostedTrader::ExpressionParser->new( );
isa_ok($expr, 'Finance::HostedTrader::ExpressionParser');

throws_ok { $expr->getIndicatorData( { rubbish => 1 } ) } qr/invalid arg in getIndicatorData: rubbish/, 'Invalid argument in getIndicatorData';
throws_ok { $expr->getSignalData( { rubbish => 1 } ) } qr/invalid arg in _getSignalSql: rubbish/, 'Invalid argument in getSignalData';
throws_ok { $expr->getSystemData( { rubbish => 1 } ) } qr/invalid arg in _getSignalSql: rubbish/, 'Invalid argument in getSystemData';
throws_ok { $expr->checkSignal( { rubbish => 1 } ) } qr/invalid arg in checkSignal: rubbish/, 'Invalid argument in checkSignal';

