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
my $datetimeNow = UnixDate('2010-07-26 00:00:00', '%Y-%m-%d %H:%M:%S');
my $tradingStop = UnixDate('2010-07-31 00:00:00', '%Y-%m-%d %H:%M:%S');


my $account = Finance::HostedTrader::Account->new(
                username => $username,
                password => $password,
                simulatedTime => $datetimeNow,
                expressionParser => $signal_processor );

my $systems = loadSystems('system.yml');

my $debug = 0;
while ($datetimeNow lt $tradingStop) {
    foreach my $system (@$systems) {
        logger($datetimeNow);
        checkSystem($account, $system, 'long');
        checkSystem($account, $system, 'short');
    }
    $datetimeNow = UnixDate(DateCalc($datetimeNow, '+ 5minutes'), '%Y-%m-%d %H:%M:%S');
    $account->simulatedTime($datetimeNow);
}

#$account->storePositions();

foreach my $direction (qw(long short)){
foreach my $system (@$systems) {
my $symbols = $system->{symbols}->{$direction};

foreach my $symbol ( @$symbols ) {
my $positions = $account->getPosition($symbol);
print "$symbol $system->{name} $direction\n";
foreach my $trade (@{ $positions->trades }) {
    print $trade->openDate, ' ', $trade->openPrice, ' ', $trade->size, ' ', $trade->direction, "\n";
}
print "\n";
}
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
                    endPeriod => $datetimeNow,
                    numItems => 1,
                    debug => 0,
                } );
                my $currentPrice = $stopLoss->[0]->[1];
                $stopLoss = $stopLoss->[0]->[2];
                my $pointsToSL = abs($stopLoss - $currentPrice) * $account->getMultiplier($symbol);
                my $trade_size = int(( $max_loss / $move_per_point ) / ( $pointsToSL ));
                warn qq|
$datetimeNow
symbol: $symbol
maxLoss: $max_loss
movePP: $move_per_point
stopLoss: $stopLoss
current: $currentPrice
TradeSize: $trade_size
                |;
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
    my $startPeriod = UnixDate(DateCalc($datetimeNow, '- 1hour'), '%Y-%m-%d %H:%M:%S');
    my $data = $signal_processor->getSignalData(
        {
            'expr'            => $expr,
            'symbol'          => $symbol,
            'tf'              => $timeframe,
            'maxLoadedItems'  => $maxLoadedItems,
            'startPeriod'     => $startPeriod,
            'endPeriod'       => $datetimeNow,
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

    print "$msg\n";
}
