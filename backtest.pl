#!/usr/bin/perl
use strict;
use warnings;

use Finance::HostedTrader::Config;
use Finance::HostedTrader::ExpressionParser;
use Finance::HostedTrader::Trade;

use Data::Dumper;
use Date::Manip;
use Getopt::Long;
use Pod::Usage;

my ( $timeframe, $max_loaded_items, $symbols_txt, $debug, $help, $startPeriod, $endPeriod ) =
  ( '5min', 100000, '', 0, 0, '6 months ago', 'today' );

GetOptions(
    "timeframe=s"         => \$timeframe,
    "debug"               => \$debug,
    "symbols=s"           => \$symbols_txt,
    "max-loaded-items=i"  => \$max_loaded_items,
    "start=s" => \$startPeriod,
    "end=s" => \$endPeriod,
) || pod2usage(2);
pod2usage(1) if ($help);

my $cfg              = Finance::HostedTrader::Config->new();
my $signal_processor = Finance::HostedTrader::ExpressionParser->new();

my $symbols = $cfg->symbols->natural;

$symbols = [ split( ',', $symbols_txt ) ] if ($symbols_txt);

my $enterLongSignal = "crossoverup(close, ema(close,200)+5*atr(14))";
my $exitLongSignal = "low < min(close,576)";
my $direction = 'long';

my $enterShortSignal = "crossoverdown(close, ema(close,200)-5*atr(14))";
my $exitShortSignal = "high > max(close,576)";



foreach my $symbol ( @{$symbols} ) {
#    backtest($symbol, $enterLongSignal,  $exitLongSignal,  $timeframe, $max_loaded_items, $startPeriod, $endPeriod, 'long');
    backtest($symbol, $enterShortSignal, $exitShortSignal, $timeframe, $max_loaded_items, $startPeriod, $endPeriod, 'short');
}


sub backtest {
    my ($symbol, $enterSignal, $exitSignal, $timeframe, $max_loaded_items, $startPeriod, $endPeriod, $direction) = @_;
$startPeriod = UnixDate($startPeriod, '%Y-%m-%d %H:%M:%S');
$endPeriod = UnixDate($endPeriod, '%Y-%m-%d %H:%M:%S');
    my $trades = getTrades($symbol, $enterSignal, $exitSignal, $timeframe, $max_loaded_items, $startPeriod, $endPeriod, $direction);

my $max_profit = 0;
my $max_loss = 0;
my $num_losses = 0;
my $num_trades = scalar(@$trades);
my $total_profit = 0;

foreach my $t (@$trades) {
    my $profit = $t->profit;
    $max_profit = $profit if ($profit > $max_profit);
    $max_loss = $profit if ($profit < $max_loss);
    $total_profit += $profit;
    $num_losses++ if ($profit < 0);

    print $t->openDate, ',', $t->closeDate, ',', $t->profit,"\n";
}


my $avg_profit = 0;
my $num_gains = $num_trades - $num_losses;
$avg_profit = $total_profit / $num_trades if ($num_trades);

print qq|
Symbol: $symbol
Start Date: $startPeriod
End Date: $endPeriod
Number of trades :  $num_trades
Gains: $num_gains
Losses: $num_losses
Max Gain: $max_profit
Max Loss: $max_loss
Avg Gain: $avg_profit
|;
}


#Trade object
#Symbol
#Open Date
#Open Price
#Close Date
#Close Price
#Profit
#MaxDrawDown
#MaxPrice


sub getTrades {
    my ($symbol, $enterSignal, $exitSignal, $timeframe, $max_loaded_items, $startPeriod, $endPeriod, $direction) = @_;
    my $data = $signal_processor->getSystemData(
        {
            'enter'           => $enterSignal,
            'exit'            => $exitSignal,
            'symbol'          => $symbol,
            'tf'              => $timeframe,
            'maxLoadedItems'  => $max_loaded_items,
            'startPeriod'     => $startPeriod,
            'endPeriod'       => $endPeriod,
            'debug'=>0,
        }
    );

my $state = 'close';
my @trades;
my $trade;
foreach my $d (@$data) {
    if ($state eq 'close') {
        if ($d->[0] eq 'ENTRY') {
            $state = 'open';
            $trade = Finance::HostedTrader::Trade->new(
                'direction' => $direction,
                'symbol' => $symbol,
                'openDate' => $d->[1],
                'openPrice' => $d->[2],
            );
        }
    } elsif ($state eq 'open') {
        if ($d->[0] eq 'EXIT') {
            $state = 'close';
            $trade->closeDate($d->[1]);
            $trade->closePrice($d->[2]);
            push @trades, $trade;
        }
    } else {
        die('unknown state ' . $state);
    }
}

if ($state eq 'open') {
    my $d = $data->[scalar(@$data)-1];

    $trade->closeDate($d->[1]);
    $trade->closePrice($d->[2]);
    push @trades, $trade;
}
return \@trades;
}
