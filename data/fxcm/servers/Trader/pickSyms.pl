#!/usr/bin/perl

use strict;
use warnings;

use Config::Any;
use Data::Dumper;
use YAML::Tiny;


use Systems;
use FXCMServer;
use Finance::HostedTrader::Config;
use Finance::HostedTrader::ExpressionParser;


my $system = Systems::loadSystem('trendfollow');

# getSymbols returns a list of symbols to be traded in the system loaded above
my $newSymbols = getSymbols();

my $trades = getCurrentTrades();
#List of symbols for which there are open short positions
my @symbols_to_keep_short = map {$_->{symbol}} grep {$_->{direction} eq 'short'} @{$trades}; 
#List of symbols for which there are open long positions
my @symbols_to_keep_long = map {$_->{symbol}} grep {$_->{direction} eq 'long'} @{$trades};

#Add symbols for which there are existing positions to the list
#If these are not kept in the trade list, open positions in these symbols will 
#not be closed by the system
$system->{symbols}->{short} = \@symbols_to_keep_short;
$system->{symbols}->{long} = \@symbols_to_keep_long;

#Now add to the trade list symbols triggered by the system as trade opportunities
foreach my $item ( @$newSymbols ) {
    my ($symbol, $tradeDirection) = @$item;

#Don't add a symbol if it already exists in the list (avoid duplicates)
    next if (grep {/$symbol/} @{ $system->{symbols}->{$tradeDirection} });
    push @{ $system->{symbols}->{$tradeDirection} }, $symbol;
}

my $yml = YAML::Tiny->new;
$yml->[0] = $system;
print $yml->write_string;

sub getCurrentTrades {
#Call FXCMServer from limited scope
#so that we release the TCP connection
#to the single threaded server
#as soon as possible
# TODO this code should be agnostic to FXCMServer, instead should be using Finance::HostedTrader::Account
my $s = FXCMServer->new();

return $s->getTrades();
}

#Return list of symbols to add to the system
sub getSymbols {
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

#Return list of all available symbols
sub getAllSymbols {
my $cfg         = Finance::HostedTrader::Config->new();

return $cfg->symbols->all;
}
