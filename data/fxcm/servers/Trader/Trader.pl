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
                    Systems::loadSystem('trendfollow'),
                    Systems::loadSystem('countertrend'),
                );

foreach my $system (@systems) {
    logger("Loaded system " . $system->{name});
}

my $debug = 0;
while (1) {
    foreach my $system (@systems) {
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
    my $symbols = $system->{symbols}->{$direction};

    foreach my $symbol ( @$symbols ) {
        my $pos_size = $account->getPosition($symbol)->size;

        if (!$pos_size) {
            my $signal = $system->{signals}->{enter}->{$direction};
            logger("Checking $system->{name} $symbol $direction") if ($verbose);
            my $result = checkSignal($signal->{signal}, $symbol, $direction, $signal->{timeframe}, $signal->{maxLoadedItems});
            if ($result) {
                my ($amount, $value, $stopLoss) = getTradeSize($account, $system, $signal, $symbol, $direction);
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
            my $signal = $system->{signals}->{exit}->{$direction};
            my $result = checkSignal($signal->{signal}, $symbol, $direction, $signal->{timeframe}, $signal->{maxLoadedItems});
            if ($result) {
                logger("Closing position for $symbol $direction ( $pos_size )");
                $account->closeTrades($symbol);
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

sub checkSignal {
    my ($expr, $symbol, $direction, $timeframe, $maxLoadedItems) = @_;
#    logger("Signal $expr");
#    Hardcoded -1hour, means check signals ocurring in the last hour
#    would be better to use the date of the last signal instead
    my $startPeriod = UnixDate(DateCalc('now', '- 1hour'), '%Y-%m-%d %H:%M:%S');
    my $data = $signal_processor->getSignalData(
        {
            'expr'            => $expr,
            'symbol'          => $symbol,
            'tf'              => $timeframe,
            'maxLoadedItems'  => $maxLoadedItems,
            'startPeriod'     => $startPeriod,
            'numItems'        => 1,
            'debug'           => $debug,
        }
    );

    return $data->[0] if defined($data);
    return undef;
}

sub getTradeSize {
my $account = shift;
my $system = shift;
my $signal = shift;
my $symbol = shift;
my $direction = shift;

my $value;
my $maxLossPts;

    my $maxLoss   = $account->getBalance * $system->{maxExposure} / 100;
    my $stopLoss = $signal_processor->getIndicatorData( {
                symbol  => $symbol,
                tf      => $signal->{timeframe},
                fields  => 'datetime, ' . $signal->{initialStop},
                maxLoadedItems => $signal->{maxLoadedItems},
                numItems => 1,
                debug => 0,
    } );
    $stopLoss = $stopLoss->[0]->[1];
    my $base = uc(substr($symbol, -3));
    if ($base ne "GBP") {
        $maxLoss *= $account->getAsk("GBP$base");
    }

    if ($direction eq "long") {
        $value = $account->getAsk($symbol);
        $maxLossPts = $value - $stopLoss;
    } else {
        $value = $account->getBid($symbol);
        $maxLossPts = $stopLoss - $value;
    }

    if ( $maxLossPts <= 0 ) {
        die("Tried to set stop to " . $stopLoss . " but current price is " . $value);
    }
    my $baseUnit = $account->baseUnit($symbol); #This is the minimum amount that can be trader for the symbol
    my $amount = ($maxLoss / $maxLossPts) / $baseUnit;
    $amount = int($amount) * $baseUnit;
    return ($amount, $value, $stopLoss);
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
