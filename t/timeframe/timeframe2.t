#!/usr/bin/perl

use strict;
use warnings;

use Datasource;
use Data::Dumper;
use Test::More qw(no_plan);

my $ds = Datasource->new();
my $dbh = $ds->{dbh};

my $BASE_SYMBOL = "EURUSD";
my $TEST_TABLE_ONE = "T2_ONE";
my $TEST_TABLE_TWO = "T2_TWO";
my $naturalTFs = $ds->getNaturalTimeframes;
my $syntheticTFs = $ds->getSyntheticTimeframes;

my %existingSymbols = map { $_ => 1} @{$ds->getAllSymbols};

foreach my $tf (@{$naturalTFs}) {
	my $available_timeframe = $tf;
	foreach my $TEST_TABLE ($TEST_TABLE_ONE, $TEST_TABLE_TWO) {
		diag("Creating $TEST_TABLE");
		$dbh->do("DROP TABLE IF EXISTS $TEST_TABLE\_$tf");
		$dbh->do("CREATE TABLE $TEST_TABLE\_$tf LIKE $BASE_SYMBOL\_$tf");
		$dbh->do("INSERT INTO $TEST_TABLE\_$tf (datetime, open, low, high, close) SELECT * FROM $BASE_SYMBOL\_$tf");
	}

	foreach my $stf (@{$syntheticTFs}) {
		foreach my $TEST_TABLE ($TEST_TABLE_ONE, $TEST_TABLE_TWO) {
			$dbh->do("DROP TABLE IF EXISTS $TEST_TABLE\_$stf");
			$dbh->do("CREATE TABLE $TEST_TABLE\_$stf LIKE $BASE_SYMBOL\_$stf");
		}

		diag("Converting $TEST_TABLE_ONE $stf");
        $ds->convertOHLCTimeSeries($TEST_TABLE_ONE,
                                  $tf,
                                  $stf,
                                  '0000-00-00',
                                  '9999-99-99' );

		diag("Converting $TEST_TABLE_TWO $stf");
        $ds->convertOHLCTimeSeries($TEST_TABLE_TWO,
                                  $available_timeframe,
                                  $stf,
                                  '0000-00-00',
                                  '9999-99-99' );

		diag("Comparint $TEST_TABLE_ONE w $TEST_TABLE_TWO");
		my @data;
		foreach my $TEST_TABLE ($TEST_TABLE_ONE, $TEST_TABLE_TWO) {
		    my $sth = $dbh->prepare("SELECT * FROM $TEST_TABLE\_$stf ORDER BY datetime") or die($DBI::errstr);
		    $sth->execute() or die($DBI::errstr);
		    push @data, $sth->fetchall_arrayref() or die($DBI::errstr);
			$sth->finish or die($DBI::errstr);
		}
		is_deeply($data[0], $data[1], "Compute timeframe $stf from both $tf and $available_timeframe and compare result");
		$available_timeframe = $stf;
	}
}
