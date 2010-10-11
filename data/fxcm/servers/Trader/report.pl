#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

use Finance::HostedTrader::Account;
use Finance::HostedTrader::ExpressionParser;
use Systems;


my $account = Finance::HostedTrader::Account->new(
                username => 'none',
                password => 'not implemented',
              );
my $processor = Finance::HostedTrader::ExpressionParser->new();


my $trades = $account->_getCurrentTrades();


print "TRADES:\n-------";
foreach my $trade (@$trades) {
=pod
    my $currentExit = $processor->getIndicatorData( {
        symbol          => $trade->{symbol},
        numItems        => 1,
        fields          =>  'datetime,' . $data->{signals}->{exit}->{currentExitPoint},
        maxLoadedItems  => $data->{signals}->{enter}->{args}->{maxLoadedItems},
        tf              => $data->{signals}->{enter}->{args}->{timeframe},
    } );
    $currentExit = $currentExit->[0];
=cut
    my $marketPrice = ($trade->{direction} eq 'short' ? $account->getAsk($trade->{symbol}) : $account->getBid($trade->{symbol}));
    print qq|
Symbol: $trade->{symbol}
Direction: $trade->{direction}
Open Date: $trade->{openDate}
Open Price: $trade->{openPrice}
Size: $trade->{size}
Stop Loss: 
Current Price:  $marketPrice
|;
}

foreach my $system_name ( qw/trendfollow countertrend/ ) {
    my $system = Systems->new( name => $system_name );
    my $data = $system->data;
    my $symbols = $data->{symbols};
    print "\nSystem $system_name Market Price/Entry Price:\n-------------\n";

    foreach my $direction (qw /long short/) {
        foreach my $symbol (@{$symbols->{$direction}}) {

            my $currentEntry = $processor->getIndicatorData( {
                        symbol  => $symbol,
                        numItems => 1,
                        fields          =>  'datetime,' . $data->{signals}->{enter}->{$direction}->{currentEntryPoint},
                        maxLoadedItems  => $data->{signals}->{enter}->{args}->{maxLoadedItems},
                        tf              => $data->{signals}->{enter}->{args}->{timeframe},
            } );
            $currentEntry = $currentEntry->[0];


            print $symbol, " ", 
                ($direction eq 'short' ? $account->getAsk($symbol) : $account->getBid($symbol)), "/",
                $currentEntry->[1], " ", $direction,
                "\n";
        }
    }
}










####OLD - Simpler and faster but less generic
sub _getSymbolsTrendFollow {
    my $symbols = getAllSymbols();
    my @results;
    my $processor   = Finance::HostedTrader::ExpressionParser->new();

    my $rv = { long => [], short => [] };

    foreach my $symbol (@$symbols) {
        my $data = $processor->getIndicatorData( {
            'fields'          => "datetime,abs(trend(close,21)),trend(close,21)",
            'symbol'        => $symbol,
            'tf'            => 'week',
            'maxLoadedItems'=> 41,
            'numItems'      => 1,
            'debug'         => 0,
        });
        $data = $data->[0];
        push @results, [ $symbol, ($data->[2] > 0 ? 'long' : 'short'), $data->[1] ] if ($data->[1] > 1);
    }

    my @sorted = sort { $b->[2] <=> $a->[2] } @results ;
    splice @sorted, 5;

    foreach my $item (@sorted) {
        push @{ $rv->{long} }, $item->[0] if ($item->[1] eq 'long');
        push @{ $rv->{short} }, $item->[0] if ($item->[1] eq 'short');
    }
    return $rv;
}
