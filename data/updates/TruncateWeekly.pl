#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use Finance::HostedTrader::Datasource;
use Data::Dumper;

my ( $timeframes_txt, $symbols_txt );

my $result =
  GetOptions( "timeframes=s", \$timeframes_txt, "symbols=s", \$symbols_txt, );

my $db = Finance::HostedTrader::Datasource->new();

my $symbols;
if ( !defined($symbols_txt) ) {
    $symbols = $db->getAllSymbols;
}
elsif ( $symbols_txt eq 'natural' ) {
    $symbols = $db->getNaturalSymbols;
}
elsif ( $symbols_txt eq 'synthetics' ) {
    $symbols = $db->getSyntheticSymbols;
}
else {
    $symbols = [ split( ',', $symbols_txt ) ] if ($symbols_txt);
}

my $timeframes = [604800];
$timeframes = [ split( ',', $timeframes_txt ) ] if ($timeframes_txt);

foreach my $symbol ( @{$symbols} ) {
    foreach my $tf ( @{$timeframes} ) {

        print qq /TRUNCATE TABLE `$symbol\_$tf`;
/;

    }
}
