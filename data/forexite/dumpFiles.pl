#!/usr/bin/perl
=head1 NAME

Dumps csv files and dumps them to a fixed directory (/home/joao/download)

=head1 SYNOPSIS

    dumpFiles --timeframes=tf_id1,tf_id2... [--verbose] [--help]

=head1 DESCRIPTION

This will dump files for every natural and synthetic symbol defined in the config file.
Relies on the external zip command to zip up csv files.

=head2 OPTIONS

=over 12

=item C<--timeframes=tf>

Required. A comma separated list of timeframe ids.

=item C<--help>

Display usage information.

=item C<--verbose>

Verbose output.


=back



=head1 LICENSE

This is released under the MIT license. See L<http://www.opensource.org/licenses/mit-license.php>.

=head1 AUTHOR

Joao Costa - L<http://zonalivre.org/>

=head1 SEE ALSO

L<Finance::HostedTrader::Datasource>
L<Finance::HostedTrader::Config>
L<Finance::HostedTrader::ExpressionParser>

=cut

use strict;
use warnings;

use Finance::HostedTrader::Datasource;
use Finance::HostedTrader::Config;
use Finance::HostedTrader::ExpressionParser;

use Data::Dumper;
use Getopt::Long;
use Pod::Usage;

use constant BASE_PATH => '/home/joao/download';
my ( $verbose, $timeframes_txt, $help ) = ( 0, '', 0 );

my $result =
  GetOptions( "verbose", \$verbose, "timeframes=s", \$timeframes_txt, ) || pod2usage(2);
pod2usage(1) if ($help || !$timeframes_txt);

my $db               = Finance::HostedTrader::Datasource->new();
my $cfg              = $db->cfg;
my $signal_processor = Finance::HostedTrader::ExpressionParser->new($db);
my $symbols          = $cfg->symbols->all();

die("No timeframes specified") unless ($timeframes_txt);
my $tfs = [ split( ',', $timeframes_txt ) ];

foreach my $tf ( @{$tfs} ) {
    $tf = $cfg->timeframes->getTimeframeName($tf);
    foreach my $symbol ( @{$symbols} ) {
        print "$symbol $tf\n" if ($verbose);
        my $data = $signal_processor->getIndicatorData(
            {
                'fields' => 'datetime,open,low,high,close',
                'symbol' => $symbol,
                'tf'     => $tf,
                'cacheResults' => 0,
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
