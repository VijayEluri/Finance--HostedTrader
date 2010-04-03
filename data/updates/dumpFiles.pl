#!/usr/bin/perl

use strict;
use warnings;

use Finance::HostedTrader::Datasource;
use Finance::HostedTrader::ExpressionParser;

use Data::Dumper;
use Getopt::Long;

use constant BASE_PATH => '/home/fxhistor/download';
my ( $verbose, $timeframes_txt ) = ( 0, '' );

my $result =
  GetOptions( "verbose", \$verbose, "timeframes=s", \$timeframes_txt, );

my $db               = Finance::HostedTrader::Datasource->new();
my $signal_processor = Finance::HostedTrader::ExpressionParser->new($db);
my $symbols          = $db->getAllSymbols;

die("No timeframes specified") unless ($timeframes_txt);
my $tfs = [ split( ',', $timeframes_txt ) ];

foreach my $tf ( @{$tfs} ) {
    $tf = $db->getTimeframeName($tf);
    foreach my $symbol ( @{$symbols} ) {
        print "$symbol $tf\n" if ($verbose);
        my $data = $signal_processor->getIndicatorData(
            {
                'expr'   => 'open,low,high,close',
                'symbol' => $symbol,
                'tf'     => $tf,
            }
        );

        my $filepath     = BASE_PATH . "/$symbol\_$tf.csv";
        my $zip_filepath = BASE_PATH . "/$symbol\_$tf.zip";
        open FILE, ">$filepath"
          or die("Cannot open $filepath for writting:\n$!\n");
        print FILE '<TICKER>,<DATE>,<TIME>,<OPEN>,<LOW>,<HIGH>,<CLOSE>' . "\n";
        foreach ( @{$data} ) {
            my $datetime = @{$_}[0];
            $datetime =~ s/ /,/;
            $datetime =~ s/-//g;
            print FILE $symbol,
                ','
              . $datetime . ','
              . @{$_}[1] . ','
              . @{$_}[2] . ','
              . @{$_}[3] . ','
              . @{$_}[4] . "\n";
        }
        close(FILE);
        `rm -f "$zip_filepath";zip -r -j "$zip_filepath" "$filepath"`;
    }
}
