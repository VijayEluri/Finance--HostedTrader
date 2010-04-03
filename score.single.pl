#!/usr/bin/perl

use strict;
use warnings;

use Finance::HostedTrader::Datasource;
use Finance::HostedTrader::ExpressionParser;

use Data::Dumper;
use Getopt::Long;

my ( $timeframe, $max_loaded_items, $verbose ) = ( 'week', 1000, 0 );

my $result = GetOptions( "timeframe=s", \$timeframe, "max-loaded-items=i",
    \$max_loaded_items, "verbose", \$verbose, ) || exit(1);

my $db               = Finance::HostedTrader::Datasource->new();
my $signal_processor = Finance::HostedTrader::ExpressionParser->new($db);
my %scores;

my $symbols    = $db->getNaturalSymbols;
my $synthetics = $db->getSyntheticSymbols;
foreach my $symbol ( @{$symbols}, @{$synthetics} ) {
    my $data = $signal_processor->getIndicatorData(
        {
            'expr'            => 'ema(trend(close,21),13)',
            'symbol'          => $symbol,
            'tf'              => $timeframe,
            'maxLoadedItems'  => $max_loaded_items,
            'maxDisplayItems' => 1
        }
    );
    $scores{$symbol} = $data->[0]->[1];
}

my @items = qw(AUD CAD CHF EUR GBP NZD JPY USD XAU XAG);

foreach my $item (@items) {
    print $item, "\t", getScore($item), "\n";
}

sub getScore {
    my $item = shift;
    my @scores2;
    my $others = join( '|', grep { !/$item/ } @items );
    push @scores2, grep { /$item($others)/ } keys(%scores);
    push @scores2, grep { /($others)$item/ } keys(%scores);

    #print STDERR $item,scalar(@scores2),"\n";
    #print STDERR $item,Dumper(\@scores2),"\n" if ($item eq 'XAU');
    my $rv = 0;
    foreach my $pair (@scores2) {

        #print STDERR $pair,"\t",$scores{$pair},"\n" if ($item eq 'XAU');
        if ( substr( $pair, 0, 3 ) eq $item ) {
            print "\t$pair\n" unless ( defined( $scores{$pair} ) );
            $rv += $scores{$pair};
        }
        else {
            $rv -= $scores{$pair};
        }
    }
    return $rv;
}
