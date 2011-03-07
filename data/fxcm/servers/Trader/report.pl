#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;

use Finance::HostedTrader::Account;
use Systems;

my ($address, $port) = ('127.0.0.1', 1500);

GetOptions(
    "address=s" => \$address,
    "port=i"    => \$port,
);

my $account = Finance::HostedTrader::Account->new(
                address => $address,
                port => $port,
              );
my $processor = Finance::HostedTrader::ExpressionParser->new();


my $trades = $account->_getCurrentTrades();
my $nav = $account->getNav();


print "ACCOUNT NAV: " . $nav . "\n\n\n";


print "TRADES:\n-------";
my $system = Systems->new( name => 'trendfollow' );
foreach my $trade (@$trades) {
    my $stopLoss = $system->getExitValue($trade->{symbol}, $trade->{direction});
    my $marketPrice = ($trade->{direction} eq 'short' ? $account->getAsk($trade->{symbol}) : $account->getBid($trade->{symbol}));
    my $pl;
    $pl = ( $trade->{direction} eq 'long' ? $marketPrice - $trade->{openPrice} : $trade->{openPrice} - $marketPrice) * $trade->{size};
    my $baseCurrencyPL = sprintf "%.4f", $account->convertToBaseCurrency($pl, substr($trade->{symbol}, 3));
    my $percentPL = sprintf "%.2f", 100 * $baseCurrencyPL / $nav;

    print qq|
Symbol: $trade->{symbol}
Direction: $trade->{direction}
Open Date: $trade->{openDate}
Open Price: $trade->{openPrice}
Size: $trade->{size}
Stop Loss: $stopLoss
Current Price:  $marketPrice
Current P/L: $baseCurrencyPL ($percentPL%)
|;
}

print "\n";

foreach my $system_name ( qw/trendfollow/ ) {
    my $system = Systems->new( name => $system_name );
    my $data = $system->data;
    my $symbols = $data->{symbols};
    print "\nSystem $system_name Market Price/Entry Price/Exit Price:\n-------------\n";

    foreach my $direction (qw /long short/) {
        foreach my $symbol (@{$symbols->{$direction}}) {
            my $currentExit = $system->getExitValue($symbol, $direction);
            my $currentEntry = $system->getEntryValue($symbol, $direction);

            print $symbol, " ", 
                ($direction eq 'long' ? $account->getAsk($symbol) : $account->getBid($symbol)), "/",
                $currentEntry, "/", $currentExit, " ", $direction,
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
