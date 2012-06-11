#!/usr/bin/perl

use strict;
use warnings;

use Finance::FXCM::Simple;

my ($username, $password, $accountType, $fxcmTimeframe, $numItemsToDownload, @symbols) = @ARGV;

my $fxcm = Finance::FXCM::Simple->new($username, $password, $accountType, 'http://www.fxcorporate.com/Hosts.jsp');

#TODO Need some kind of module that maps FXCM timeframe codes to Finance::HostedTrader timeframe codes
my $timeframe;
if ($fxcmTimeframe eq "m1") {
    $timeframe = 60;
} elsif ($fxcmTimeframe eq "m5") {
   $ timeframe = 300;
} elsif ($fxcmTimeframe eq "H1") {
    $timeframe = 3600;
} elsif ($fxcmTimeframe eq "D1") {
    $timeframe = 86400;
} elsif ($fxcmTimeframe eq "W1") {
    $timeframe = 604800;
} else {
    die("Unknown timeframe '$fxcmTimeframe'");
}


foreach my $symbol (@symbols) {
    my $filename = $symbol;
    $filename =~ s|/||g;
    $filename .= "_$timeframe";

    $fxcm->saveHistoricalDataToFile("/tmp/$filename", $symbol, $fxcmTimeframe, $numItemsToDownload);
}
