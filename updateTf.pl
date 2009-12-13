#!/usr/bin/perl

use strict;
use warnings;

use Finance::HostedTrader::Datasource;

use Data::Dumper;
use Date::Manip;
use Getopt::Long;


my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time-24*60*60);
my ($start_date, $end_date) = ('0001-01-01', '9998-12-31');
my ($symbols_txt, $timeframe_txt);
my $available_timeframe = 'min';
my $verbose = 0;

my $result = GetOptions(
                        "start=s", \$start_date,
                        "end=s", \$end_date,
                        "verbose", \$verbose,
                        "symbols=s", \$symbols_txt,
                        "timeframe=s", \$timeframe_txt,
						"available-timeframe=s", \$available_timeframe,
                        ) or die($!);

$start_date = UnixDate($start_date, "%Y-%m-%d %H:%M:%S") or die("Cannot parse $start_date");
$end_date = UnixDate($end_date, "%Y-%m-%d %H:%M:%S") or die("Cannot parse $end_date");

my $db = Finance::HostedTrader::Datasource->new();
my $symbols;
if (!defined($symbols_txt)) {
	$symbols = $db->getAllSymbols;
} elsif ($symbols_txt eq 'natural') {
	$symbols = $db->getNaturalSymbols;
} elsif ($symbols_txt eq 'synthetics') {
	$symbols = $db->getSyntheticSymbols;
} else {
	$symbols = [split(',',$symbols_txt)] if ($symbols_txt);
}

my $tfs = $db->getSyntheticTimeframes();
$tfs = [split(',',$timeframe_txt)] if ($timeframe_txt);

$available_timeframe = $db->getTimeframeID($available_timeframe);

foreach my $tf (@{$tfs}) {
    next if ($tf == $available_timeframe);
    foreach my $symbol (@{$symbols}) {
        print "$symbol\t$available_timeframe\t$tf\t$start_date\t$end_date\n" if ($verbose);
        $db->convertOHLCTimeSeries( $symbol,
                                    $available_timeframe,
                                    $tf,
                                    $start_date,
                                    $end_date );
    }
    $available_timeframe = $tf;
}
