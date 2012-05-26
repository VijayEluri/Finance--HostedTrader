#!/usr/bin/perl

use strict;
use warnings;

use Finance::HostedTrader::Datasource;
use Finance::HostedTrader::Config;

use Data::Dumper;
use Test::More tests=>4;
use Test::Exception;
use File::Find;

my $config_file;

find(sub { $config_file = $File::Find::name if ($_ eq "fx.yml" && $File::Find::name =~ m|synthetics/fx.yml$|) }, './');
die("Could not find config file t/synthetics/fx.yml") if (!$config_file);

my $ds = Finance::HostedTrader::Datasource->new(
	cfg => Finance::HostedTrader::Config->new(
		files => [
			'/etc/fx.yml',
			$ENV{HOME} . '/.fx.yml',
			$config_file
		]
	)
);
my $cfg = $ds->cfg;
my $dbh = $ds->dbh;

my $BASE_SYMBOL = "EURUSD";
my $naturalTFs = $cfg->timeframes->natural;
my $syntheticTFs = $cfg->timeframes->synthetic;

my %existingSymbols = map { $_ => 1} @{$cfg->symbols->all()};

#Synthetics work by checking existing symbols for the presence of USD
#and doing appropriate math to calculate the new symbol
#eg: AUDJPY = AUDUSD * USDJPY
#    GBPEUR = GBPUSD / EURUSD
#    CADJPY = USDCAD / USDJPY
#

my $testcases = [
        {
		name => 'Synthetic AAAJJJ = AAAUSD * JJJUSD',
		n1 => { symbol => 'AAAUSD', data => [['0001-01-01 00:00:00', 2, 1, 3, 2]]},
		n2 => { symbol => 'USDJJJ', data => [['0001-01-01 00:00:00', 2, 1, 3, 2]]},
		s  => { symbol => 'AAAJJJ', data => [['0001-01-01 00:00:00', '4.0000', '1.0000', '9.0000', '4.0000']]},
	},
        {
		name => 'Synthetic GGGEEE = GGGUSD / EEEUSD',
		n1 => { symbol => 'GGGUSD', data => [['0001-01-01 00:00:00', 2, 1, 3, 2]]},
		n2 => { symbol => 'EEEUSD', data => [['0001-01-01 00:00:00', 2, 1, 3, 2]]},
		s  => { symbol => 'GGGEEE', data => [['0001-01-01 00:00:00', '1.0000', '0.3333', '3.0000', '1.0000']]},
	},
        {
		name => 'Synthetic CCCJJJ = USDCCC / USDJJJ',
		n1 => { symbol => 'USDCCC', data => [['0001-01-01 00:00:00', 2, 1, 3, 2]]},
		n2 => { symbol => 'USDJJJ', data => [['0001-01-01 00:00:00', 2, 1, 3, 2]]},
		s  => { symbol => 'CCCJJJ', data => [['0001-01-01 00:00:00', '1.0000', '0.3333', '3.0000', '1.0000']]},
	},

];

my $tf = $naturalTFs->[0]; #Just need any available timeframe

foreach my $test (@$testcases) {
	foreach my $table_data ($test->{n1},$test->{n2}) {
		my $table = $table_data->{symbol};

		$dbh->do("DROP TABLE IF EXISTS $table\_$tf");
		$dbh->do("CREATE TABLE $table\_$tf LIKE $BASE_SYMBOL\_$tf");
		foreach my $data (@{$table_data->{data}}) {
			my $data_str = join("','", @$data);
			#die("INSERT INTO $table\_$tf (datetime, open, low, high, close) SELECT $data_str");
			$dbh->do("INSERT INTO $table\_$tf (datetime, open, low, high, close) SELECT '$data_str'");
		}
	}
	my $synt_table = $test->{s}->{symbol};
	$dbh->do("DROP TABLE IF EXISTS $synt_table\_$tf");
	$dbh->do("CREATE TABLE $synt_table\_$tf LIKE $BASE_SYMBOL\_$tf");

	$ds->createSynthetic($synt_table, $tf);

	my $sth = $dbh->prepare("SELECT * FROM $synt_table\_$tf ORDER BY datetime") or die($DBI::errstr);
	$sth->execute() or die($DBI::errstr);
	my $data = $sth->fetchall_arrayref() or die($DBI::errstr);
	$sth->finish or die($DBI::errstr);
	is_deeply($data, $test->{s}->{data}, $test->{name});
}

throws_ok { $ds->createSynthetic('BADBAD', $tf) } qr /Don't know how to handle/, 'Unrecognized pair';
