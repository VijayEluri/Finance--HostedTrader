#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 11;
use Test::Exception;
use Data::Dumper;
use Finance::HostedTrader::Datasource;

BEGIN {
use_ok ('Finance::HostedTrader::ExpressionParser');
}


foreach my $ds ((undef, Finance::HostedTrader::ExpressionParser->new( ))) {
	my $expr = Finance::HostedTrader::ExpressionParser->new( $ds );
	isa_ok($expr, 'Finance::HostedTrader::ExpressionParser');

	throws_ok { $expr->getIndicatorData( { rubbish => 1 } ) } qr/invalid arg in getIndicatorData: rubbish/, 'Invalid argument in getIndicatorData';
	throws_ok { $expr->getSignalData( { rubbish => 1 } ) } qr/invalid arg in _getSignalSql: rubbish/, 'Invalid argument in getSignalData';
	throws_ok { $expr->getSystemData( { rubbish => 1 } ) } qr/invalid arg in _getSignalSql: rubbish/, 'Invalid argument in getSystemData';
	throws_ok { $expr->checkSignal( { rubbish => 1 } ) } qr/invalid arg in checkSignal: rubbish/, 'Invalid argument in checkSignal';
}
