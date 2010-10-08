#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;


use Systems;
use Finance::HostedTrader::Config;
use Finance::HostedTrader::ExpressionParser;


my $newSymbols = getSymbolsTrendFollow();
my $system = Systems->new( name => 'trendfollow' );
$system->updateSymbols($newSymbols);


#$newSymbols = getSymbolsTrendFollow();
#$system = Systems->new( name => 'countertrend');
#$system->updateSymbols($newSymbols);


#Return list of symbols to add to the system
sub getSymbolsTrendFollow {
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

sub getSymbolsCounterTrend {
}

#Return list of all available symbols
sub getAllSymbols {
my $cfg         = Finance::HostedTrader::Config->new();

return $cfg->symbols->all;
}
