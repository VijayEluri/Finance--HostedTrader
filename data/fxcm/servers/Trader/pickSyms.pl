#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;


use Systems;
use Finance::HostedTrader::Config;
use Finance::HostedTrader::ExpressionParser;


my $system = Systems->new( name => 'trendfollow' );
my $newSymbols = getSymbolsTrendFollow();
$system->updateSymbols($newSymbols);


#Return list of symbols to add to the system
sub getSymbolsTrendFollow {
    my $symbols = getAllSymbols();
    my @results;
    my $processor   = Finance::HostedTrader::ExpressionParser->new();

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
    return \@sorted;
}

sub getSymbolsCounterTrend {
}

#Return list of all available symbols
sub getAllSymbols {
my $cfg         = Finance::HostedTrader::Config->new();

return $cfg->symbols->all;
}
