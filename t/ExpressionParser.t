#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 33;
use Test::Exception;
use Data::Dumper;
use Finance::HostedTrader::Datasource;

BEGIN {
use_ok ('Finance::HostedTrader::ExpressionParser');
}


foreach my $ds ((undef, Finance::HostedTrader::Datasource->new( ))) {
	my $expr = Finance::HostedTrader::ExpressionParser->new( $ds );
	isa_ok($expr, 'Finance::HostedTrader::ExpressionParser');

	throws_ok { $expr->getSignalData( { rubbish => 1 } ) } qr/invalid arg in _getSignalSql: rubbish/, 'Invalid argument in getSignalData';
	throws_ok { $expr->checkSignal( { rubbish => 1 } ) } qr/invalid arg in checkSignal: rubbish/, 'Invalid argument in checkSignal';

# test getIndicatorData
{
	throws_ok { $expr->getIndicatorData( { rubbish => 1 } ) } qr/invalid arg in getIndicatorData: rubbish/, 'Invalid argument in getIndicatorData';
	throws_ok { $expr->getIndicatorData( { } ) } qr/No fields set for indicator/, 'Missing "fields" argument in getIndicatorData';
	throws_ok { $expr->getIndicatorData( { fields => 'datetime,close' } ) } qr/No symbol set for indicator/, 'Missing "symbol" argument in getIndicatorData';
	throws_ok { $expr->getIndicatorData( { fields => 'rubbish', symbol => 'EURUSD' } ) } qr/Syntax error in indicator/, 'Indicator syntax error in getIndicatorData';
}


#test getSystemData
{
    my $data;
	throws_ok { $expr->getSystemData( { rubbish => 1 } ) } qr/invalid arg in _getSignalSql: rubbish/, 'Invalid argument in getSystemData';
	throws_ok { $expr->getSystemData( { } ) } qr/No expression set for signal/, 'No entry signal set';
	throws_ok { $expr->getSystemData( { enter => 'rubbish' } ) } qr/No symbol set/, 'No symbol set';
	throws_ok { $expr->getSystemData( { enter => 'rubbish', symbol => 'EURUSD' } ) } qr/Syntax error in signal/, 'Syntax error in entry signal';
	throws_ok { $expr->getSystemData( { enter => 'crossoverup(close, ema(close,200))', symbol => 'EURUSD' } ) } qr/No expression set for signal/, 'No expression set for signal';
	throws_ok { $expr->getSystemData( { enter => 'crossoverup(close, ema(close,200))', exit => 'rubbish', symbol => 'EURUSD' } ) } qr/Syntax error in signal/, 'Syntax error in exit signal';
	throws_ok { $expr->getSystemData( { enter => 'crossoverup(close, ema(close,200))', exit => 'crossoverdown(close, ema(close,200))', symbol => 'EURUSD' } ) } qr/Incorrect usage of UNION and ORDER BY/, 'Forgot to pass noOrderBy';
    lives_ok { $data = $expr->getSystemData( { enter => 'crossoverup(close, ema(close,200))', exit => 'crossoverdown(close, ema(close,200))', symbol => 'EURUSD', noOrderBy => 1 } ) }  'Got System data';
    is(ref($data), 'ARRAY', 'data is array');
}

}
