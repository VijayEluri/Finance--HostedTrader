#!/usr/bin/perl

use strict;
use warnings;

use Finance::HostedTrader::Datasource;
use Finance::HostedTrader::Config;
use Data::Dumper;
use Test::More tests => 2;
use Test::Exception;

my $cfg= Finance::HostedTrader::Config->new();
my $ds = Finance::HostedTrader::Datasource->new();
my $dbh = $ds->dbh;

my $naturalTFs = $cfg->timeframes->natural;
my $syntheticTFs = $cfg->timeframes->synthetic;


throws_ok {
    $ds->convertOHLCTimeSeries('SOME',
                               300,
                               60,
                               '0000-00-00',
                               '9999-99-99' ) } qr/Cannot convert to a smaller timeframe/, 'Convert from larger to smaller exception';

throws_ok {
    $ds->convertOHLCTimeSeries('SOME',
                               -2,
                               -1,
                               '0000-00-00',
                               '9999-99-99' ) } qr/timeframe not supported \(-1\)/, 'Convert to invalid timeframe exception';
