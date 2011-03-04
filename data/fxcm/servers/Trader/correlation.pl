#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Statistics::RankCorrelation;

use Finance::HostedTrader::ExpressionParser;

#my @syms = qw/XAGUSD XAUUSD USDCHF AUDUSD EURCHF/;# XAUUSD AUDJPY USDCHF NZDUSD EURCAD AUDUSD EURJPY NZDJPY GBPUSD EURGBP USDJPY EURUSD/;

my %tradeable;
my $signal_processor = Finance::HostedTrader::ExpressionParser->new();

my $correlation_limit = 0.66;


foreach my $newSym (@ARGV) {
    my $data=getData($newSym);
    my $maxCorrelation = 0;

    foreach my $k (keys %tradeable) {
        my $c = Statistics::RankCorrelation->new( $data, $tradeable{$k} );
        my $corr = abs($c->spearman);
        print "$newSym\t$k\t$corr\n";

        $maxCorrelation = $corr if ($corr > $maxCorrelation);
        last if ($maxCorrelation >= $correlation_limit);
    }

    $tradeable{$newSym} = $data if ($maxCorrelation < $correlation_limit);
}

my @t = keys(%tradeable);
print Dumper(\@t);



sub getData {
    my $symbol = shift;

    my $data = $signal_processor->getIndicatorData(
        {
            'fields'          => 'datetime,close',
            'symbol'          => $symbol,
            'tf'              => 'day',
            'maxLoadedItems'  => 40,
            'numItems'        => 40
        }
    );

    my @d = map { $_->[1] } @$data;

    return \@d;
}
