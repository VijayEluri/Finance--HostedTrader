#!/usr/bin/perl

use strict;
use warnings;

use Finance::HostedTrader::Config;
use Finance::HostedTrader::ExpressionParser;

use Data::Dumper;
use Getopt::Long;

my ( $timeframe, $max_loaded_items, $verbose ) = ( 'week', 1000, 0 );

my $result = GetOptions( "timeframe=s", \$timeframe, "max-loaded-items=i",
    \$max_loaded_items, "verbose", \$verbose, ) || exit(1);

my $cfg               = Finance::HostedTrader::Config->new();
my $signal_processor = Finance::HostedTrader::ExpressionParser->new();
my %scores;

my $symbols    = $cfg->symbols->all;
foreach my $symbol ( @{$symbols} ) {
    my $data = $signal_processor->getIndicatorData(
        {
            'fields'          => 'ema(trend(close,21),13)',
            'symbol'          => $symbol,
            'tf'              => $timeframe,
            'maxLoadedItems'  => $max_loaded_items,
            'numItems'        => 290
        }
      )
      ; #TODO: 295 is hardcoded here because it seems the current database has at least 295 weekly data records for each pair
    $data = [ grep { defined( $_->[0] ) } @{$data} ];

    #	$scores{$symbol} = $data->[0]->[1];
    $scores{$symbol} = $data;
}

#print Dumper(\$scores{EURUSD});exit;
my @items = qw(AUD CAD CHF EUR GBP NZD JPY USD XAU XAG);

foreach my $item (@items) {
    printScore($item);
}

sub printScore {
    my $item = shift;
    my @scores2;
    my $others = join( '|', grep { !/$item/ } @items );
    push @scores2, grep { /$item($others)/ } keys(%scores);
    push @scores2, grep { /($others)$item/ } keys(%scores);

    #print STDERR $item,scalar(@scores2),"\n";
    #print STDERR $item,Dumper(\@scores2),"\n" if ($item eq 'XAU');

    my $size = scalar( @{ $scores{ $scores2[0] } } );

    for ( my $i = 0 ; $i < $size ; $i++ ) {
        my $rv   = 0;
        my $date = $scores{ $scores2[0] }->[$i]->[0];

        foreach my $pair (@scores2) {
            my ( $date_check, $score ) = @{ $scores{$pair}->[$i] };

            die("$pair $i $item bad data\n$date\t$date_check\n")
              unless ( $date eq $date_check );

            if ( substr( $pair, 0, 3 ) eq $item ) {
                $rv += $score;
            }
            else {
                $rv -= $score;
            }

            #print "$pair\t$date\t$score\n" if ($item eq 'XAU');
        }
        print "$item\t$date\t$rv\n";

    }

}
