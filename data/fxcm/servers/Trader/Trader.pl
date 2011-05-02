#!/usr/bin/perl

use strict;
use warnings;
$| = 1;
use Getopt::Long;
use Data::Dumper;
use Data::Compare;
use Pod::Usage;


use Finance::HostedTrader::Factory::Account;
use Finance::HostedTrader::SystemTrader;
use Finance::HostedTrader::System;
use Finance::HostedTrader::Report;

my ($verbose, $help, $address, $port, $class, $startDate, $endDate) = (0, 0, '127.0.0.1', 1500, 'FXCM', 'now', '10 years');

my $result = GetOptions(
    "class=s",  \$class,
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
                SUBCLASS => $class,
                address => $address,
                port => $port,
                startDate => $startDate,
                endDate => $endDate,
                system => $trendfollow,
            )->create_instance();

my @systems =   (   
                    Finance::HostedTrader::SystemTrader->new( system => $trendfollow, account => $account ),
                );

logger("STARTUP");

foreach my $system (@systems) {
    logger("Loaded system " . $system->system->name);
}

my $debug = 0;
my $symbolsLastUpdated = 0;
while (1) {
    my $systemTrader = $systems[0];
    # Applies system filters and updates list of symbols traded by this system
    # Updates symbol list every 15 minutes
    if ( $account->getServerEpoch() - $systemTrader->symbolsLastUpdated() > 900 ) {
        my %current_symbols;
        my %existing_symbols;
        if ($verbose) {
            my $symbols_long = $systemTrader->system->symbols('long');
            my $symbols_short = $systemTrader->system->symbols('short');
            if ($verbose > 1) {
                logger("Current symbol list");
                logger("long: " . join(',', @$symbols_long));
                logger("short: " . join(',', @$symbols_short));
            }
            $current_symbols{long} = $symbols_long;
            $current_symbols{short} = $symbols_short;
        }
        $systemTrader->updateSymbols();
        if ($verbose) {
            my $symbols_long = $systemTrader->system->symbols('long');
            my $symbols_short = $systemTrader->system->symbols('short');
            if ($verbose > 1) {
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
    if ($verbose && 0) {
        # print a report if the day changed
        $currentTime = substr($account->getServerDateTime, 0, 10) if ($verbose);
        my $report = Finance::HostedTrader::Report->new( account => $account, systemTrader => $systemTrader );
        logger("NAV = " . $account->getNav) if ($previousTime ne $currentTime);
        logger("\n".$report->openPositions) if ($previousTime ne $currentTime);
        logger("\n".$report->systemEntryExit) if ($previousTime ne $currentTime);
    }
    if ( $account->getServerDateTime() gt $account->endDate ) {
        my $report = Finance::HostedTrader::Report->new( account => $account, systemTrader => $systemTrader );
        logger("Final report");
        logger("NAV = " . $account->getNav);
        logger("\n".$report->openPositions);
        logger("\n".$report->systemEntryExit);
        last;
    }
}

sub checkSystem {
    my ($account, $systemTrader, $direction) = @_;

    my $symbols = $systemTrader->system->symbols($direction);

    foreach my $symbol ( @$symbols ) {
        my $position = $account->getPosition($symbol);
        my $posSize = $position->size;
        my $numOpenTrades = $position->numOpenTrades();

        if ($numOpenTrades < $systemTrader->maxNumberTrades) {
            logger("Checking ".$systemTrader->system->name." $symbol $direction") if ($verbose > 1);
            my $result = $systemTrader->checkEntrySignal($symbol, $direction);
            if ($result) {
                my ($amount, $value, $stopLoss) = $systemTrader->getTradeSize($symbol, $direction, $position);
                if ($verbose > 1 && $result) {
                    logger("$symbol $direction at " . $result->[0] . " Amount=" . $amount . " value=" . $value . " stopLoss=" . $stopLoss);
                }
                next if ($amount <= 0);
                my $report = Finance::HostedTrader::Report->new( account => $account, systemTrader => $systemTrader );
                logger("Positions before open trade\n" . $report->openPositions);
                logger("\n".$report->systemEntryExit);
                logger("Adding position for $symbol $direction ($amount)");

                TRY_OPENTRADE: foreach my $try (1..3) {
                    eval {
                        my ($orderID, $rate) = $account->openMarket($symbol, $direction, $amount);
                        logger("symbol=$symbol,direction=$direction,amount=$amount,orderID=$orderID,rate=$rate");
                        1;
                    } or do {
                        logger($@);
                        next;
                    };
                    sendMail('Trading Robot - Open Trade ' . $symbol, qq {Open Trade:
Instrument: $symbol
Direction: $direction
Amount: $amount
Current Value: $value
Stop Loss: $stopLoss
                });
                    logger("NAV=" . $account->getNav() . "\n" . $report->openPositions);
                    logger("\n".$report->systemEntryExit);
                    last TRY_OPENTRADE;
                }
            }
        }

        if ($posSize) {
            my $result = $systemTrader->checkExitSignal($symbol, $direction);
            if ($result) {
                logger("Closing position for $symbol $direction ( $posSize )");
                $account->closeTrades($symbol, $direction);
                my $value;
                if ($direction eq "long") {
                    $value = $account->getAsk($symbol);
                } else {
                    $value = $account->getBid($symbol);
                }
                sendMail('Trading Robot - Close Trade ' . $symbol, qq {Close Trade:
Instrument: $symbol
Direction: $direction
Position Size: $posSize
Current Value: $value
                });
                my $report = Finance::HostedTrader::Report->new( account => $account, systemTrader => $systemTrader );
                logger("NAV=" . $account->getNav() . "\n" . $report->openPositions);
                logger("\n".$report->systemEntryExit);
            }
        }
    }
}

sub logger {
    my $msg = shift;

    my $datetimeNow = $account->getServerDateTime;
    print "[$datetimeNow] $msg\n";
}


sub sendMail {
my ($subject, $content) = @_;
use MIME::Lite;

    logger($content);
    return if ($class eq 'UnitTest');
    ### Create a new single-part message, to send a GIF file:
    my $msg = MIME::Lite->new(
        From     => 'fxhistor@fxhistoricaldata.com',
        To       => 'joaocosta@zonalivre.org',
        Subject  => $subject,
        Data     => $content
    );
    $msg->send; # send via default
}
