#!/usr/bin/perl

use strict;
use warnings;

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
my $tradesFile = '/home/fxhistor/.wine/drive_c/trades.yml';

my $account = Finance::HostedTrader::Account->new(
                username => $username,
                password => $password,
                expressionParser => $signal_processor );

my $systems = loadSystems('system.yml');

my $debug = 0;
while (1) {
    foreach my $system (@$systems) {
        $account->loadPositionsFromYML($tradesFile);
        checkSystem($account, $system, 'long');
        checkSystem($account, $system, 'short');
        sleep(30);
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
                my $max_loss   = $account->getBalance * $system->{maxExposure} / 100;
                my $move_per_point = $account->getMovePerPoint();
                my $stopLoss = $signal_processor->getIndicatorData( {
                    symbol  => $symbol,
                    tf      => $signal->{timeframe},
                    fields  => 'datetime, close,' . $signal->{initialStop},
                    maxLoadedItems => $signal->{maxLoadedItems},
                    numItems => 1,
                    debug => 0,
                } );
                my $currentPrice = $stopLoss->[0]->[1];
                $stopLoss = $stopLoss->[0]->[2];
                my $pointsToSL = abs($stopLoss - $currentPrice) * $account->getMultiplier($symbol);
                my $trade_size = int(( $max_loss / $move_per_point ) / ( $pointsToSL ));
                logger("Adding position for $symbol $direction, initialStop=$stopLoss ( $trade_size )");
                $account->marketOrder($symbol, $trade_size, $direction);
            }
        }

        if ($pos_size) {
            logger("Check close $symbol $direction");
            my $signal = $system->{signals}->{exit}->{$direction};
            my $result = checkSignal($signal->{signal}, $symbol, $direction, $signal->{timeframe}, $signal->{maxLoadedItems});
            logger(Dumper(\$result));
            if ($result) {
                logger("Closing position for $symbol $direction ( $pos_size )");
                $account->marketOrder($symbol, $pos_size, ($direction eq 'long' ? 'short' : 'long' ));
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
