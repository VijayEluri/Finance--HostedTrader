#!/usr/bin/perl 
package Finance::HostedTrader;
=head1 synthetics.pl

Create synthetic data for FX pairs based on existing USD pairs

=head1 SYNOPSIS

    synthetics.pl --timeframe=tf [--verbose] [--symbols=s]

=head1 DESCRIPTION

The timeframe argument is mandatory

The following 
eg: AUDJPY = AUDUSD * USDJPY
    GBPEUR = GBPUSD / EURUSD

=head2 OPTIONS

=over 12

=item C<--timeframe=tf>

Required argument. Specifies a single timeframe for which
synthetic data will be created.

tf can be a valid integer timeframe as defined in L<Finance::HostedTrader::Datasource>

=item C<--symbols=s>

Comma separated list of symbols for which to create synthetic data.
If not supplied, defaults to the list entry in the config file item "symbols.synthetic".

=item C<--help>

Display usage information

=item C<--verbose>

Verbose output.


=back

=head1 LICENSE

This is released under the MIT license. See L<http://www.opensource.org/licenses/mit-license.php>.

=head1 AUTHOR

Joao Costa - L<http://zonalivre.org/>

=head1 SEE ALSO

L<Finance::HostedTrader::Datasource>

=cut

use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;
use Pod::Usage;
use Finance::HostedTrader::Datasource;

my ( $timeframe, $verbose, $help );

my $db         = Finance::HostedTrader::Datasource->new();
my $cfg        = $db->cfg;
my $synthetics = $cfg->symbols->synthetic;

my $symbols_txt;
my $result = GetOptions(
    "symbols=s", \$symbols_txt, "timeframe=i", \$timeframe,
    "verbose",   \$verbose,
    "help", \$help,
) || pod2usage(2);
pod2usage(1) if ($help || !$timeframe);
$synthetics = [ split( ',', $symbols_txt ) ] if ($symbols_txt);

foreach my $synthetic (@$synthetics) {
    print "$synthetic [$timeframe]" if ($verbose);
    $db->createSynthetic( $synthetic, $timeframe );
}
