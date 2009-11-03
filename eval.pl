#!/usr/bin/perl

use strict;
use warnings;

use Finance::HostedTrader::Datasource;
use Finance::HostedTrader::ExpressionParser;

use Data::Dumper;
use Getopt::Long;

my ($timeframe, $max_loaded_items, $max_display_items, $symbols_txt) = ('day', 1000, 1);

GetOptions(
	"timeframe=s"	=>	\$timeframe,
	"symbols=s"		=>	\$symbols_txt,
	"max-loaded-items=i"	=> \$max_loaded_items,
	"max-display-items=i"	=> \$max_display_items,
);


my $db = Finance::HostedTrader::Datasource->new();
my $signal_processor = Finance::HostedTrader::ExpressionParser->new($db);

my $symbols = $db->getAllSymbols;

$symbols = [ split(',', $symbols_txt) ] if ($symbols_txt);
foreach my $symbol (@{$symbols}) {
    my $data = $signal_processor->getIndicatorData({ 
								'expr'   => $ARGV[0], 
								'symbol' => $symbol, 
								'tf'     => $timeframe, 
								'maxLoadedItems' => $max_loaded_items, 
								'maxDisplayItems' => $max_display_items });
	foreach my $item (@$data) {
    	print "$symbol\t" . join("\t", @$item) . "\n";
	}
#    print "$symbol\t".Dumper(\$data);
}
