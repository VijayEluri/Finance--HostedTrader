#!/usr/bin/perl

use strict;
use warnings;
$| = 1;
#use Proc::Daemon;
#Proc::Daemon::Init;
use Config::Any;
use Data::Dumper;
use Date::Manip;
use Finance::HostedTrader::ExpressionParser;
use Finance::HostedTrader::Account;
use Finance::HostedTrader::Trade;

my $username = 'joaocosta';
my $password = 'password';

my $signal_processor = Finance::HostedTrader::ExpressionParser->new();

my $account = Finance::HostedTrader::Account->new(
                username => $username,
                password => $password,
              );

my $systems = loadSystems('system.yml') || die('Could not load systems from file "system.yml"');

my $debug = 0;
while (1) {
    foreach my $system (@$systems) {
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
        logger("$symbol = $pos_size");

        if (!$pos_size) {
            logger("Check open $symbol $direction");
            my $signal = $system->{signals}->{enter}->{$direction};
            my $result = checkSignal($signal->{signal}, $symbol, $direction, $signal->{timeframe}, $signal->{maxLoadedItems});
            logger(Dumper(\$result));
            if ($result) {
                my ($amount, $value, $stopLoss) = getTradeSize($account, $system, $signal, $symbol, $direction);
                logger("Adding position for $symbol $direction ($amount)");

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
            logger("Check close $symbol $direction");
            my $signal = $system->{signals}->{exit}->{$direction};
            my $result = checkSignal($signal->{signal}, $symbol, $direction, $signal->{timeframe}, $signal->{maxLoadedItems});
            logger(Dumper(\$result));
            if ($result) {
                logger("Closing position for $symbol $direction ( $pos_size )");
                $account->closeTrades($symbol);
                logger("before sendMail");
                sendMail(qq {Close Trade:
Instrument: $symbol
Direction: $direction
Position Size: $pos_size
                });
                logger("after sendMail");
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
    my $amount = ($maxLoss / $maxLossPts) / 10000;#This bit is specific to FXCM, since they only accept multiples of 10.000
    $amount = int($amount) * 10000;
    return ($amount, $value, $stopLoss);
}

sub loadSystems {
    my $file = shift;
    my $system = Config::Any->load_files(
        {
            files => [$file],
            use_ext => 1,
            flatten_to_hash => 1,
        }
    );

    return $system->{$file} if defined($system);
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
#        Cc       => 'elad.sharf@gmail.com',
        Subject  => 'Trading Robot',
        Data     => $content
    );
    $msg->send; # send via default
}
