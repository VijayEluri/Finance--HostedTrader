#!/usr/bin/perl

use strict;
use warnings;

use Cwd;
use Datasource;
use Data::Dumper;
use File::Basename;
use File::Find;
use Test::More qw(no_plan);

#To generate load files:
#SELECT * INTO OUTFILE '/tmp/EURUSD_60' FROM EURUSD_60 WHERE datetime < '2002-01-01';


my $cwd = cwd;
my $ds = Datasource->new();
my $dbh = $ds->{dbh};

my $BASE_SYMBOL = "EURUSD";
my $naturalTFs = $ds->getNaturalTimeframes;
my $syntheticTFs = $ds->getSyntheticTimeframes;

my %existingSymbols = map { $_ => 1} @{$ds->getAllSymbols};

foreach my $tf (@{$naturalTFs}) {
	find (
		sub {
			return unless (/^(.+)_$tf$/);
			my $symbol = $1;
			die("Cannot run test for symbol $symbol as it would delete its tables") if (exists $existingSymbols{$symbol});
			diag("Testing $symbol");
			$dbh->do("DROP TABLE IF EXISTS $symbol\_$tf");
			$dbh->do("CREATE TABLE $symbol\_$tf LIKE $BASE_SYMBOL\_$tf");
			$dbh->do("LOAD DATA LOCAL INFILE '$_' INTO TABLE $symbol\_$tf");

			foreach my $stf (@{$syntheticTFs}) {
				$dbh->do("DROP TABLE IF EXISTS $symbol\_$stf");
				$dbh->do("CREATE TABLE $symbol\_$stf LIKE $BASE_SYMBOL\_$stf");

		        $ds->convertOHLCTimeSeries( $symbol,
                                    $tf,
                                    $stf,
                                    '0000-00-00',
                                    '9999-99-99' );

				diag("Updated synthetic timeframe $stf");

				my $table = "$symbol\_$stf";
				open FILE, '>', $table.".got" or die("Cannot open file $table for writting\n$!");
			    my $sth = $dbh->prepare("SELECT * FROM $symbol\_$stf") or die($DBI::errstr);
			    $sth->execute() or die($DBI::errstr);
			    my $data = $sth->fetchall_arrayref() or die($DBI::errstr);
				$sth->finish or die($DBI::errstr);
				foreach my $row (@$data) {
					print FILE join("\t", @$row),"\n";
				}
				close(FILE);
				diag("Dumped got results for timeframe $stf");
#TODO: test files $table and $table.'got' are equal Algorithm::Diff
			}
		}, '.');
}
