#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Finance::HostedTrader::Config;
use Finance::HostedTrader::Account::FXCM::ForexConnect;
use Finance::FXCM::Simple;
use Pod::Usage;

my $numItemsToDownload = 10;
my ($timeframe, $numItemsToDownload, @symbols, $symbols_txt);

my $result = GetOptions(
    "symbols=s", \$symbols_txt,
    "timeframe=s", \$table_type,
    "numItems=i", \$numItemsToDownload,
    "help", \$help)  or pod2usage(1);

my $cfg     = Finance::HostedTrader::Config->new();
if (!$symbols_txt) {
    @symbols = split( ',', $symbols_txt ) if ($symbols_txt);
} else {
    @symbols = @{ $cfg->symbols->natural };
}

my $fxcmTimeframe = Finance::HostedTrader::Account::FXCM::ForexConnect::convertTimeframeToFXCM($timeframe);
my $providerCfg = $cfg->tradingProviders->{fxcm};
my $fxcm = Finance::FXCM::Simple->new($providerCfg->username, $providerCfg->password, $providerCfg->accountType, $providerCfg->serverURL);

foreach my $symbol (@symbols) {
    my $filename = $symbol . "_timeframe";

    $fxcm->saveHistoricalDataToFile($filename, Finance::HostedTrader::Account::FXCM::ForexConnect::convertSymbolToFXCM($symbol), $fxcmTimeframe, $numItemsToDownload);
}
