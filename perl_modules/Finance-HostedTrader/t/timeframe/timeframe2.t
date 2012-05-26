#!/usr/bin/perl

use strict;
use warnings;

use Finance::HostedTrader::Datasource;
use Finance::HostedTrader::Config;
use Data::Dumper;
use Test::More tests => 9;

my $cfg= Finance::HostedTrader::Config->new();
my $ds = Finance::HostedTrader::Datasource->new();
my $dbh = $ds->dbh;

my $BASE_SYMBOL = "EURUSD";
my $TEST_TABLE_ONE = "T2_ONE";
my $TEST_TABLE_TWO = "T2_TWO";
my $naturalTFs = $cfg->timeframes->natural;
my $syntheticTFs = $cfg->timeframes->synthetic;

#This test will copy the EURUSD table in the smaller timeframe
#then convert that copy into a larger timeframe
#it then compares the end result with the original EURUSD table in the target timeframe
#This assumes EURUSD data in all timeframes (as defined in the config file) exist

foreach my $tf (@{$naturalTFs}) {
	my $available_timeframe = $tf;
	foreach my $TEST_TABLE ($TEST_TABLE_ONE, $TEST_TABLE_TWO) {
        diag("Creating $TEST_TABLE\_$tf");
		$dbh->do("DROP TABLE IF EXISTS $TEST_TABLE\_$tf") || die($DBI::errstr);
		$dbh->do("CREATE TABLE $TEST_TABLE\_$tf LIKE $BASE_SYMBOL\_$tf") || die($DBI::errstr);
		$dbh->do("INSERT INTO $TEST_TABLE\_$tf (datetime, open, low, high, close) SELECT * FROM $BASE_SYMBOL\_$tf ORDER BY datetime DESC LIMIT 100000") || die($DBI::errstr);
	}
    diag("Tables created");

#	foreach my $stf (@{$syntheticTFs}) {
	for (my $i=0;$i<scalar(@{$syntheticTFs});$i++) {
        my $stf = $syntheticTFs->[$i];
            foreach my $TEST_TABLE ($TEST_TABLE_ONE, $TEST_TABLE_TWO) {
			$dbh->do("DROP TABLE IF EXISTS $TEST_TABLE\_$stf") || die($DBI::errstr);
			$dbh->do("CREATE TABLE $TEST_TABLE\_$stf LIKE $BASE_SYMBOL\_$stf") || die($DBI::errstr);
		}

        $ds->convertOHLCTimeSeries($TEST_TABLE_ONE,
                                  $tf,
                                  $stf,
                                  '0000-00-00',
                                  '9999-99-99' );

        $ds->convertOHLCTimeSeries($TEST_TABLE_TWO,
                                  $available_timeframe,
                                  $stf,
                                  '0000-00-00',
                                  '9999-99-99' );

		my @data;
		foreach my $TEST_TABLE ($TEST_TABLE_ONE, $TEST_TABLE_TWO) {
		    my $sth = $dbh->prepare("SELECT * FROM $TEST_TABLE\_$stf ORDER BY datetime") or die($DBI::errstr);
		    $sth->execute() or die($DBI::errstr);
		    push @data, $sth->fetchall_arrayref() or die($DBI::errstr);
			$sth->finish or die($DBI::errstr);
		}
		is_deeply($data[0], $data[1], "Compute timeframe $stf from both $tf and $available_timeframe and compare result");
        my $next_timeframe = $syntheticTFs->[$i+1];
		$available_timeframe = $stf if ($next_timeframe && !($next_timeframe % $stf));
	}
}
