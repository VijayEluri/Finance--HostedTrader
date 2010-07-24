#!/usr/bin/perl

use strict;
use warnings;

use Proc::Daemon;
#Proc::Daemon::Init;
use Config::Any;
use Data::Dumper;
use Date::Manip;
use Finance::HostedTrader::ExpressionParser;
use Finance::HostedTrader::Account;
use Finance::HostedTrader::Trade;


my $account = Finance::HostedTrader::Account->new();

my $signal_processor = Finance::HostedTrader::ExpressionParser->new();
my $systems = loadSystems('system.yml');

my $datetimeNow = UnixDate('2010-07-20 13:00:00', '%Y-%m-%d %H:%M:%S');
my $tradingStop = UnixDate('2010-07-24 00:00:00', '%Y-%m-%d %H:%M:%S');


while ($datetimeNow lt $tradingStop) {
    foreach my $system (@$systems) {
        logger($datetimeNow);
#        checkSystem($account, $system, 'long');
        checkSystem($account, $system, 'short');
    }
    $datetimeNow = UnixDate(DateCalc($datetimeNow, '+ 5minutes'), '%Y-%m-%d %H:%M:%S');
}


sub checkSystem {
    my ($account, $system, $direction) = @_;
    my $symbols = $system->{symbols}->{$direction};

    foreach my $symbol ( @$symbols ) {
        my $pos_size = $account->getPosition($symbol)->size;
        logger("$symbol = $pos_size");

        my $trade_size = $system->{maxExposure} - $pos_size;
        if ($trade_size) {
            logger("Check open $symbol $direction");
            my $signal = checkSignal($system->{$direction.'EnterSignal'}, $symbol, $direction, $system->{timeframe}, $system->{maxLoadedItems});
            logger(Dumper(\$signal));
            if ($signal) {
                logger("Adding position for $symbol $direction ( $trade_size )");
                $account->addPosition($symbol, $direction, $trade_size);
            }
        }

        if ($pos_size) {
            logger("Check close $symbol $direction");
            my $signal = checkSignal($system->{$direction.'ExitSignal'}, $symbol, $direction, $system->{timeframe}, $system->{maxLoadedItems});
            logger(Dumper(\$signal));
            if ($signal) {
                logger("Closing position for $symbol $direction ( $pos_size )");
                $account->closePosition($symbol, $direction, $pos_size);
            }
        }
    }
}

sub checkSignal {
    my ($expr, $symbol, $direction, $timeframe, $maxLoadedItems) = @_;
#    logger("Signal $expr");
#    TODO: Hardcoded -1hour, should depend on system timeframe
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
            'debug'           => 0,
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
