#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

use Finance::HostedTrader::Account;
use Systems;


my $account = Finance::HostedTrader::Account->new(
                username => 'none',
                password => 'not implemented',
              );


my $trades = $account->_getCurrentTrades();

print "TRADES:\n-------\n" . Dumper(\$trades);

foreach my $system_name ( qw/trendfollow countertrend/ ) {
    my $system = Systems->new( name => $system_name );
    my $data = $system->data;
    print "System $system_name:\n-------------" . Dumper(\$data->{symbols});
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
