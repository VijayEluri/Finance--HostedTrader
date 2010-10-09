#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;


use Systems;
use Finance::HostedTrader::Config;
use Finance::HostedTrader::ExpressionParser;


my $newSymbols = getSymbolsTrendFollow();
$newSymbols = filterTopX($newSymbols, 5);

my $system = Systems->new( name => 'trendfollow' );
$system->updateSymbols($newSymbols);


#$system = Systems->new( name => 'countertrend');
#$system->updateSymbols($newSymbols);


#Return list of symbols to add to the system
sub getSymbolsTrendFollow {
    my $symbols = getAllSymbols();
    my $processor   = Finance::HostedTrader::ExpressionParser->new();

    my $rv = { long => [], short => [] };

    foreach my $symbol (@$symbols) {
        if ($processor->checkSignal( {
            'expr' => 'trend(close,21) > 1',
            'symbol' => $symbol,
            'timeframe' => 'week',
            'maxLoadedItems' => 50,
            'period' => '8days',
            'debug' => 0,
        })) {
            push @{ $rv->{long} }, $symbol;
        } elsif ($processor->checkSignal( {
            'expr' => 'trend(close,21) < -1',
            'symbol' => $symbol,
            'timeframe' => 'week',
            'maxLoadedItems' => 50,
            'period' => '8days',
            'debug' => 0,
        })) {
            push @{ $rv->{short} }, $symbol;
        }
    }

    return $rv;
}

sub filterTopX {
    my $existing = shift;
    my $number_to_keep = shift;
    my @results;
    my $processor   = Finance::HostedTrader::ExpressionParser->new();

    my $calculateIndicator = sub {
        my $direction = shift;
        foreach my $symbol (@{ $existing->{$direction} }) {
            my $data = $processor->getIndicatorData( {
                'fields'          => "datetime,abs(trend(close,21))",
                'symbol'        => $symbol,
                'tf'            => 'week',
                'maxLoadedItems'=> 41,
                'numItems'      => 1,
                'debug'         => 0,
            } );
            $data = $data->[0];
            push @results, [ $symbol, $direction, $data->[1] ];
        }
    };

    &$calculateIndicator('long');
    &$calculateIndicator('short');

    my @sorted = sort { $b->[2] <=> $a->[2] } @results ;
    splice @sorted, $number_to_keep;

    my $rv = { long => [], short => [] };
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
