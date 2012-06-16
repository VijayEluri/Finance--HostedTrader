#!/usr/bin/perl

use strict;
use warnings;
$| = 1;
use Getopt::Long qw(:config pass_through);
use Data::Dumper;
use Data::Compare;
use Pod::Usage;


use Finance::HostedTrader::Factory::Account;
use Finance::HostedTrader::Trader;
use Finance::HostedTrader::System;
use Finance::HostedTrader::Report;

my ($verbose, $help, $accountClass, $pathToSystems) = (0, 0, 'ForexConnect', 'systems');

my $result = GetOptions(
    "class=s",          \$accountClass,
    "verbose",          \$verbose,
    "help",             \$help,
    "pathToSystems=s",  \$pathToSystems,
) || pod2usage(2);

pod2usage(1) if ($help);


my $trendfollow = Finance::HostedTrader::System->new( name => 'trendfollow', pathToSystems => $pathToSystems );

my %classArgs = map { s/^--//; split(/=/) } @ARGV;
my $account = Finance::HostedTrader::Factory::Account->new(
                SUBCLASS => $accountClass,
                system => $trendfollow,
                %classArgs,
            )->create_instance();

my @systems =   (   
                    Finance::HostedTrader::Trader->new(
                        system => $trendfollow,
                        account => $account,
                    ),
                );

logger("STARTUP") if ($verbose);

foreach my $system (@systems) {
    logger("Loaded system " . $system->system->name) if ($verbose);
}

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
            my $report;
            if ($verbose) {
                $report = Finance::HostedTrader::Report->new( account => $account, systemTrader => $systemTrader );
                logger("Positions before open trade");
                logger("NAV=" . $account->getNav());
                logger($report->openPositions);
                logger($report->systemEntryExit);
                logger("Adding position for $symbol $direction ($amount)");
            }

            $account->openMarket($symbol, $direction, $amount, $stopLoss);

            if ($verbose) {
                logger("Positions after open trade");
                logger("NAV=" . $account->getNav());
                logger($report->openPositions);
                logger($report->systemEntryExit);
            }
        }

        if ($posSize) {
            my $result = $systemTrader->checkExitSignal($symbol, $direction);
            if ($result) {
                my $report;
                if ($verbose) {
                    $report = Finance::HostedTrader::Report->new( account => $account, systemTrader => $systemTrader );
                    logger("Positions before close trades");
                    logger("NAV=" . $account->getNav());
                    logger($report->openPositions);
                    logger($report->systemEntryExit);
                    logger("Closing position for $symbol $direction ( $posSize )");
                }
                $account->closeTrades($symbol, $direction);
                if ($verbose) {
                    logger("Positions after close trades");
                    logger("NAV=" . $account->getNav());
                    logger($report->openPositions);
                    logger($report->systemEntryExit);
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
