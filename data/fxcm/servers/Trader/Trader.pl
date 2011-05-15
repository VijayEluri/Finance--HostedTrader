#!/usr/bin/perl

use strict;
use warnings;
$| = 1;
use Getopt::Long;
use Data::Dumper;
use Data::Compare;
use Pod::Usage;


use Finance::HostedTrader::Factory::Account;
use Finance::HostedTrader::Trader;
use Finance::HostedTrader::Factory::Notifier;
use Finance::HostedTrader::System;
use Finance::HostedTrader::Report;

my ($verbose, $help, $address, $port, $accountClass, $notifierClass, $expectedTradesFile, $startDate, $endDate, $dontSkipDates) = (0, 0, '127.0.0.1', 1500, 'FXCM', 'Production', undef, 'now', '10 years', 0);

my $result = GetOptions(
    "class=s",  \$accountClass,
    "notifier=s",\$notifierClass,
    "expectedTradesFile=s", \$expectedTradesFile,
    "dontSkipDates",  \$dontSkipDates,
    "address=s",\$address,
    "port=i",   \$port,
    "verbose",  \$verbose,
    "help",     \$help,
    "startDate=s",\$startDate,
    "endDate=s",  \$endDate,
) || pod2usage(2);

pod2usage(1) if ($help);

my $trendfollow = Finance::HostedTrader::System->new( name => 'trendfollow' );

my $account = Finance::HostedTrader::Factory::Account->new(
                SUBCLASS => $accountClass,
                address => $address,
                port => $port,
                startDate => $startDate,
                endDate => $endDate,
                system => $trendfollow,
                skipToDatesWithSignal => !$dontSkipDates,
            )->create_instance();

my @systems =   (   
                    Finance::HostedTrader::Trader->new(
                        system => $trendfollow,
                        account => $account,
                        notifier => Finance::HostedTrader::Factory::Notifier->new(
                                        SUBCLASS => $notifierClass,
                                        expectedTradesFile => $expectedTradesFile,
                                    )->create_instance(),
                    ),
                );

logger("STARTUP") if ($verbose);

foreach my $system (@systems) {
    logger("Loaded system " . $system->system->name) if ($verbose);
}

my $debug = 0;
my $symbolsLastUpdated = 0;
while (1) {
    my $systemTrader = $systems[0];
    # Applies system filters and updates list of symbols traded by this system
    # Updates symbol list every 15 minutes
    if ( $account->getServerEpoch() >= $systemTrader->system->getSymbolsNextUpdate() ) {
        my %current_symbols;
        my %existing_symbols;
        if ($verbose > 1) {
            my $symbols_long = $systemTrader->system->symbols('long');
            my $symbols_short = $systemTrader->system->symbols('short');
            if ($verbose > 2) {
                logger("Current symbol list");
                logger("long: " . join(',', @$symbols_long));
                logger("short: " . join(',', @$symbols_short));
            }
            $current_symbols{long} = $symbols_long;
            $current_symbols{short} = $symbols_short;
        }
        $systemTrader->updateSymbols();
        if ($verbose > 1) {
            my $symbols_long = $systemTrader->system->symbols('long');
            my $symbols_short = $systemTrader->system->symbols('short');
            if ($verbose > 2) {
                logger("Updated symbol list");
                logger("long: " . join(',', @$symbols_long));
                logger("short: " . join(',', @$symbols_short));
            }
            $existing_symbols{long} = $symbols_long;
            $existing_symbols{short} = $symbols_short;
            if (!Compare(\%current_symbols, \%existing_symbols)) {
                logger("Symbols list updated");
                logger("FROM: " . join(',', @{ $current_symbols{long} }, @{ $current_symbols{short} }));
                logger("TO  : " . join(',', @{ $existing_symbols{long} }, @{ $existing_symbols{short} }));
            }
        }

    }
    # Actually test the system
    eval {
        checkSystem($account, $systemTrader, 'long');
        1;
    } or do {
        logger($@);
    };

    eval {
        checkSystem($account, $systemTrader, 'short');
        1;
    } or do {
        logger($@);
    };

    my ($previousTime, $currentTime);
    # get current time
    $previousTime = substr($account->getServerDateTime, 0, 10) if ($verbose);
    # sleep for a bit
    $account->waitForNextTrade();
    if ($verbose > 1 && 0) {
        # print a report if the day changed
        $currentTime = substr($account->getServerDateTime, 0, 10) if ($verbose);
        my $report = Finance::HostedTrader::Report->new( account => $account, systemTrader => $systemTrader );
        logger("NAV = " . $account->getNav) if ($previousTime ne $currentTime);
        logger("\n".$report->openPositions) if ($previousTime ne $currentTime);
        logger("\n".$report->systemEntryExit) if ($previousTime ne $currentTime);
    }
    if ( $account->getServerDateTime() gt $account->endDate ) {
        if ($verbose) {
            my $report = Finance::HostedTrader::Report->new( account => $account, systemTrader => $systemTrader );
            logger("Final report");
            logger("NAV = " . $account->getNav);
            logger("\n".$report->openPositions);
            logger("\n".$report->systemEntryExit);
        }
        last;
    }
}

sub checkSystem {
    my ($account, $systemTrader, $direction) = @_;

    my $symbols = $systemTrader->system->symbols($direction);

    foreach my $symbol ( @$symbols ) {
        my $position = $account->getPosition($symbol);
        my $posSize = $position->size;

        my $result;
        if ($posSize == 0) {
            logger("Checking ".$systemTrader->system->name." $symbol $direction") if ($verbose > 2);
            $result = $systemTrader->checkEntrySignal($symbol, $direction);
        } else {
            logger("Checking ".$systemTrader->system->name." $symbol $direction") if ($verbose > 2);
            $result = $systemTrader->checkAddUpSignal($symbol, $direction);
        }
        
        if ($result) {
            my ($amount, $value, $stopLoss) = $systemTrader->getTradeSize($symbol, $direction, $position);
            if ($verbose > 2 && $result) {
                logger("$symbol $direction at " . $result->[0] . " Amount=" . $amount . " value=" . $value . " stopLoss=" . $stopLoss);
            }
            next if ($amount <= 0);
            my $report = Finance::HostedTrader::Report->new( account => $account, systemTrader => $systemTrader );
            if ($verbose) {
                logger("Positions before open trade\n" . $report->openPositions);
                logger("\n".$report->systemEntryExit);
                logger("Adding position for $symbol $direction ($amount)");
            }

            TRY_OPENTRADE: foreach my $try (1..3) {
                my ($orderID, $rate);
                eval {
                    ($orderID, $rate) = $account->openMarket($symbol, $direction, $amount);
                    logger("symbol=$symbol,direction=$direction,amount=$amount,orderID=$orderID,rate=$rate") if ($verbose);
                    1;
                } or do {
                    logger($@);
                    next;
                };
                $systemTrader->notifier->open(
                    symbol      => $symbol,
                    direction   => $direction,
                    amount      => $amount, 
                    stopLoss    => $stopLoss,
                    orderID     => $orderID,
                    rate        => $rate,
                    currentValue=> $value,
                    now         => $account->getServerDateTime(),
                    nav         => $account->getNav(),
                    balance     => $account->balance(),
                );
                if ($verbose) {
                    logger("NAV=" . $account->getNav() . "\n" . $report->openPositions);
                    logger("\n".$report->systemEntryExit);
                }
                last TRY_OPENTRADE;
            }
        }

        if ($posSize) {
            my $result = $systemTrader->checkExitSignal($symbol, $direction);
            if ($result) {
                logger("Closing position for $symbol $direction ( $posSize )") if ($verbose);
                $account->closeTrades($symbol, $direction);
                my $value;
                if ($direction eq "long") {
                    $value = $account->getAsk($symbol);
                } else {
                    $value = $account->getBid($symbol);
                }
                $systemTrader->notifier->close(
                    symbol      => $symbol,
                    direction   => $direction,
                    amount      => $posSize, 
                    currentValue=> $value,
                    now         => $account->getServerDateTime(),
                    nav         => $account->getNav(),
                    balance     => $account->balance(),
                );
                if ($verbose) {
                    my $report = Finance::HostedTrader::Report->new( account => $account, systemTrader => $systemTrader );
                    logger("NAV=" . $account->getNav() . "\n" . $report->openPositions);
                    logger("\n".$report->systemEntryExit);
                }
            }
        }
    }
}

sub logger {
    my $msg = shift;

    my $datetimeNow = $account->getServerDateTime;
    print "[$datetimeNow] $msg\n";
}
