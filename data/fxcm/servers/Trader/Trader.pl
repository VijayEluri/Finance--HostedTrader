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

my ($verbose, $help, $address, $port);

my $result = GetOptions(
    "address=s",\$address,
    "port=i",   \$port,
    "verbose",  \$verbose,
    "help",     \$help,
) || pod2usage(2);

pod2usage(1) if ($help);

logger("STARTUP");

my $signal_processor = Finance::HostedTrader::ExpressionParser->new();

my $account = Finance::HostedTrader::Account->new(
                address     => $address,
                port        => $port,
              );

my @systems =   (   
                    Systems->new( name => 'trendfollow' ),
#                    Systems->new( name => 'countertrend' ),
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
        if ( time() - $system->symbolsLastUpdated() > 900 ) {
            logger("Update symbol list") if ($verbose);
            $system->updateSymbols($account);
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
    }
    sleep(20);
}

sub checkSystem {
    my ($account, $system, $direction) = @_;

    my $symbols = $system->symbols($direction);

    foreach my $symbol ( @$symbols ) {
        my $position = $account->getPosition($symbol);
        my $posSize = $position->size;
        my $numTrades = scalar(@{ $position->trades });

        logger("Check ".$system->name." $symbol $direction [$numTrades]") if ($verbose);
        if ($numTrades < 3 && $system->checkEntrySignal($symbol, $direction)) {
            logger("Entry signal $symbol $direction");
            my ($amount, $value, $stopLoss) = $system->getTradeSize($account, $symbol, $direction);
            my $maxAmount = $account->convertBaseUnit($symbol, $posSize / 2); #If there are no trades opened, maxAmount=0, otherwise, it equals half the value of all other trades
            $amount = $maxAmount if ($maxAmount && $amount > $maxAmount); #So when adding to a position, make sure we don't add more than 50% of what we already have
            next if ($amount <= 0);
            logger("Adding position $symbol $direction ($amount)");

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
                last TRY_OPENTRADE;
            }
        } elsif ($posSize) {
            my $result = $system->checkExitSignal($symbol, $direction);
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
my ($subject, $content) = @_;
use MIME::Lite;

    logger($content);
    ### Create a new single-part message, to send a GIF file:
    my $msg = MIME::Lite->new(
        From     => 'fxhistor@fxhistoricaldata.com',
        To       => 'joaocosta@zonalivre.org',
        Subject  => $subject,
        Data     => $content
    );
    $msg->send; # send via default
}
