#!/usr/bin/perl -w

use strict;
use GT::Conf;
use GT::Eval;
use GT::DateTime;
use GT::Tools qw(:timeframe);
use GT::Calculator;
use GT::Prices;


setpriority 0, 0, 19;

GT::Conf::load();

my $code = shift or die(usage());
my $timeframe = shift or die(usage());
my $start_date = shift or die(usage());
my $end_date = shift or die(usage());
my $verbose = 0;

my $tfs = GT::Conf::get('DB::timeframes_available');
$tfs =~ s/,$timeframe//;
$tfs =~ s/$timeframe,?//;
GT::Conf::set('DB::timeframes_available', $tfs);


$timeframe = GT::DateTime::name_to_timeframe($timeframe);

warn "$code $start_date $end_date\n" if ($verbose);
my $sql = "SELECT open, high, low, close, 0, date_format(datetime, '%Y-%m-%d %H:%i:%s') FROM \$code_\$timeframe WHERE datetime >= '$start_date' and datetime <= '$end_date' ORDER BY datetime DESC";
GT::Conf::set('DB::genericdbi::prices_sql',$sql);
$sql = "SELECT close, close, close, close, 0, date_format(datetime, '%Y-%m-%d %H:%i:%s') FROM \$code_\$timeframe WHERE datetime >= '$start_date' and datetime <= '$end_date' ORDER BY datetime DESC";
GT::Conf::set('DB::genericdbi::prices_sql::1',$sql);


my $db = create_standard_object("DB::" . GT::Conf::get('DB::module'));
my ($q, $calc) = get_timeframe_data($code, $timeframe, $db);

    foreach (@{$q->{'prices'}}) {
	print @{$_}[$DATE].','.@{$_}[$OPEN].','.@{$_}[$LOW].','.@{$_}[$HIGH].','.@{$_}[$CLOSE]."\n";
    }

sub usage {
return "Converts CODE into TIMEFRAME, based on the closest available timeframe data.\nIf asked to create daily data, and hourly data exists, hourly data is used. If hourly data does not exists, but tick data exists, tick data is used.\n\nUsage:\n\t$0 CODE TIMEFRAME START_DATE END_DATE\n\n";
}
