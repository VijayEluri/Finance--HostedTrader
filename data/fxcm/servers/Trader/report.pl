#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;
use Text::ASCIITable;

use Finance::HostedTrader::Account::FXCM;
use Systems;

my ($address, $port) = ('127.0.0.1', 1500);

GetOptions(
    "address=s" => \$address,
    "port=i"    => \$port,
);

my $account = Finance::HostedTrader::Account::FXCM->new(
                address => $address,
                port => $port,
              );

my $trades = $account->getTrades();
my $nav = $account->getNav();


print "ACCOUNT NAV: " . $nav . "\n\n\n";


print "TRADES:\n-------";
my $system = Systems->new( name => 'trendfollow', account => $account );
foreach my $trade (@$trades) {
    my $stopLoss = $system->getExitValue($trade->{symbol}, $trade->{direction});
    my $marketPrice = ($trade->{direction} eq 'short' ? $account->getAsk($trade->{symbol}) : $account->getBid($trade->{symbol}));
    my $baseCurrencyPL = $trade->{pl};
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
    my $t = Text::ASCIITable->new( {headingText => $system_name} );
    $t->setCols('Symbol','Market','Entry','Exit','Direction');
    my $system = Systems->new( name => $system_name, account => $account );
    my $data = $system->data;
    my $symbols = $data->{symbols};

    foreach my $direction (qw /long short/) {
        foreach my $symbol (@{$symbols->{$direction}}) {
            my $currentExit = $system->getExitValue($symbol, $direction);
            my $currentEntry = $system->getEntryValue($symbol, $direction);

            $t->addRow( $symbol, 
                        ($direction eq 'long' ? $account->getAsk($symbol) : $account->getBid($symbol)),
                        $currentEntry, $currentExit, $direction);
        }
    }
    print $t;
}










####OLD - Simpler and faster but less generic
=pod
use Finance::HostedTrader::ExpressionParser;

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
=cut
