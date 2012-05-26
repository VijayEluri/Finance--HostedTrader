#!/usr/bin/perl

use strict;
use warnings;

use Finance::HostedTrader::Datasource;
use Finance::HostedTrader::Config;
use Data::Dumper;
use Test::More;

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

my $testCount = 0;
foreach my $naturalTF (@$naturalTFs) {
    $testCount += grep { $naturalTF <= $_  } @$syntheticTFs;
}

plan tests => $testCount;

foreach my $tf (@{$naturalTFs}) {
    diag ("Testing tf = $tf");
	my $available_timeframe = $tf;
	foreach my $TEST_TABLE ($TEST_TABLE_ONE, $TEST_TABLE_TWO) {
        diag("Creating $TEST_TABLE\_$tf");
		$dbh->do("DROP TABLE IF EXISTS $TEST_TABLE\_$tf") || die($DBI::errstr);
		$dbh->do("CREATE TABLE $TEST_TABLE\_$tf LIKE $BASE_SYMBOL\_$tf") || die($DBI::errstr);
		$dbh->do("INSERT INTO $TEST_TABLE\_$tf (datetime, open, high, low, close) SELECT datetime, open, high, low, close FROM $BASE_SYMBOL\_$tf ORDER BY datetime DESC LIMIT 100000") || die($DBI::errstr);
	}
    diag("Tables created");

	for (my $i=0;$i<scalar(@{$syntheticTFs});$i++) {
        my $syntheticTf = $syntheticTFs->[$i];
        next if ($tf >= $syntheticTf);
        foreach my $TEST_TABLE ($TEST_TABLE_ONE, $TEST_TABLE_TWO) {
			$dbh->do("DROP TABLE IF EXISTS $TEST_TABLE\_$syntheticTf") || die($DBI::errstr);
			$dbh->do("CREATE TABLE $TEST_TABLE\_$syntheticTf LIKE $BASE_SYMBOL\_$syntheticTf") || die($DBI::errstr);
		}

        $ds->convertOHLCTimeSeries(
                                symbol      => $TEST_TABLE_ONE,
                                tf_src      => $tf,
                                tf_dst      => $syntheticTf,
                                start_date  =>  '0000-00-00',
                                end_date    =>  '9999-99-99' );

        $ds->convertOHLCTimeSeries(
                                symbol      => $TEST_TABLE_TWO,
                                tf_src      => $available_timeframe,
                                tf_dst      => $syntheticTf,
                                start_date  => '0000-00-00',
                                end_date    => '9999-99-99' );

		my @data;
		foreach my $TEST_TABLE ($TEST_TABLE_ONE, $TEST_TABLE_TWO) {
		    my $sth = $dbh->prepare("SELECT * FROM $TEST_TABLE\_$syntheticTf ORDER BY datetime") or die($DBI::errstr);
		    $sth->execute() or die($DBI::errstr);
		    push @data, $sth->fetchall_arrayref() or die($DBI::errstr);
			$sth->finish or die($DBI::errstr);
		}
		is_deeply($data[0], $data[1], "Compute timeframe $syntheticTf from both $tf and $available_timeframe and compare result");
        my $next_timeframe = $syntheticTFs->[$i+1];
		$available_timeframe = $syntheticTf if ($next_timeframe && !($next_timeframe % $syntheticTf));
	}
}
