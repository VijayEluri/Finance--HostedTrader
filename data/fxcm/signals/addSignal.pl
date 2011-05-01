#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use Data::Dumper;
use Date::Manip;

use Finance::HostedTrader::Config;
use Finance::HostedTrader::DB::Trader::Schema;


my ($symbols_txt, $signal_code, $validity);

my $result = GetOptions(
                        "symbols=s", \$symbols_txt,
                        "signal-code=s", \$signal_code,
                        "validity=s", \$validity,
					);

die("give me a signal-code") if (!defined($signal_code));
my $cfg = Finance::HostedTrader::Config->new();


my $symbols;
if (!defined($symbols_txt)) {
	$symbols = $cfg->symbols->all;
} elsif ($symbols_txt eq 'natural') {
	$symbols = $cfg->symbols->natural;
} elsif ($symbols_txt eq 'synthetics') {
	$symbols = $cfg->symbols->synthetic;
} else {
	$symbols = [split(',',$symbols_txt)] if ($symbols_txt);
}

if ($validity) {
    $validity = UnixDate($validity, '%Y-%m-%d %H:%M:%S');
    die("Could not parse valid-till date") if (!defined($validity));
}

my $alerts_model = Finance::HostedTrader::DB::Trader::Schema->resultset('SignalAlerts');
foreach my $symbol (@$symbols) {
    $alerts_model->create({
        symbol      => $symbol,
        signalid    => $signal_code,
        validtill   => $validity,
    });
}
