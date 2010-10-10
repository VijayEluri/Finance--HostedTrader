#!/usr/bin/perl

use strict;
use warnings;
$| = 1;
#use Proc::Daemon;
#Proc::Daemon::Init;
use Getopt::Long;
use Data::Dumper;
use Date::Manip;
use Pod::Usage;


use Finance::HostedTrader::ExpressionParser;
use Finance::HostedTrader::Account;
use Systems;

my ($verbose, $help);

my $result = GetOptions(
    "verbose",  \$verbose,
    "help",     \$help,
) || pod2usage(2);

pod2usage(1) if ($help);

logger("STARTUP");

my $username = 'joaocosta';
my $password = 'password';

my $signal_processor = Finance::HostedTrader::ExpressionParser->new();

my $account = Finance::HostedTrader::Account->new(
                username => $username,
                password => $password,
              );

my @systems =   (   
                    Systems->new( name => 'trendfollow' ),
                    Systems->new( name => 'countertrend' ),
                );

foreach my $system (@systems) {
    logger("Loaded system " . $system->{name});
}

my $debug = 0;
my $symbolsLastUpdated = 0;
while (1) {
    foreach my $system (@systems) {
# Applies system filters and updates list of symbols traded by this system
# Updates symbol list every 15 minutes
        if ( time() - $symbolsLastUpdated > 900 ) {
            $system->updateSymbols();
            $symbolsLastUpdated = time();
        }
        eval {
            checkSystem($account, $system, 'long');
            1;
        } or do {
            logger($@);
        };

        eval {
            checkSystem($account, $system, 'short');
            1;
        } or do {
            logger($@);
        };
        sleep(20);
    }
}

sub checkSystem {
    my ($account, $system, $direction) = @_;

    my $symbols = $system->symbols($direction);

    foreach my $symbol ( @$symbols ) {
        my $pos_size = $account->getPosition($symbol)->size;

        if (!$pos_size) {
            logger("Checking ".$system->name." $symbol $direction") if ($verbose);
            my $result = $system->checkEntrySignal($symbol, $direction);
            if ($result) {
                my ($amount, $value, $stopLoss) = $system->getTradeSize($account, $symbol, $direction);
                logger("Adding position for $symbol $direction ($amount)");
                logger(Dumper(\$result));

                foreach my $try (1..3) {
                    eval {
                        $account->openMarket($symbol, $direction, $amount) if ($amount > 0);
                        1;
                    } or do {
                        logger($@);
                        next;
                    };
                    sendMail(qq {Open Trade:
Instrument: $symbol
Direction: $direction
Amount: $amount
Current Value: $value
Stop Loss: $stopLoss
                });
                    last;
                }
            }
        }

        if ($pos_size) {
            my $result = $system->checkExitSignal($symbol, $direction);
            if ($result) {
                logger("Closing position for $symbol $direction ( $pos_size )");
                $account->closeTrades($symbol, $direction);
                my $value;
                if ($direction eq "long") {
                    $value = $account->getAsk($symbol);
                } else {
                    $value = $account->getBid($symbol);
                }
                sendMail(qq {Close Trade:
Instrument: $symbol
Direction: $direction
Position Size: $pos_size
Current Value: $value
                });
            }
        }
    }
}

sub logger {
    my $msg = shift;

    my $datetimeNow = UnixDate('now', '%Y-%m-%d %H:%M:%S');
    print "[$datetimeNow] $msg\n";
}


sub sendMail {
my ($content) = @_;
use MIME::Lite;

    ### Create a new single-part message, to send a GIF file:
    my $msg = MIME::Lite->new(
        From     => 'fxhistor@fxhistoricaldata.com',
        To       => 'joaocosta@zonalivre.org',
        Cc       => 'elad.sharf@gmail.com',
        Subject  => 'Trading Robot',
        Data     => $content
    );
    $msg->send; # send via default
}
