#!/usr/bin/perl 
=head1 NAME

Outputs the value of a signal against a given symbol/timeframe


=head1 SYNOPSIS

    testSignal.pl [--timeframe=tf] [--symbol=s] expr


=head1 DESCRIPTION

Sample expressions:

rsi(close,14) > 70

ema(close,21) < ema(close,200)


=head2 OPTIONS

=over 12

=item C<--timeframe=tf>

Specifies a single timeframe for which to calculate the signal.

tf can be a valid integer timeframe as defined in L<Finance::HostedTrader::Datasource>

Defaults to day.

=item C<--symbol=s>

Symbol for which to calculate the signal.

Defaults to EURUSD.

=item C<--help>

Display usage information.

=back

=head1 LICENSE

This is released under the MIT license. See L<http://www.opensource.org/licenses/mit-license.php>.

=head1 AUTHOR

Joao Costa - L<http://zonalivre.org/>

=head1 SEE ALSO

L<Finance::HostedTrader::ExpressionParser>

=cut

use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;
use Pod::Usage;
use Finance::HostedTrader::ExpressionParser;

my $signal_processor = Finance::HostedTrader::ExpressionParser->new();

my ( $timeframe, $symbols_txt, $debug, $help ) =
  ( 'day', 'EURUSD', 0, 0 );

GetOptions(
    "timeframe=s"         => \$timeframe,
    "help"               => \$help,
    "debug"               => \$debug,
    "symbol=s"           => \$symbols_txt,
) || pod2usage(2);
pod2usage(1) if ($help);

my $expr = join( ' ', @ARGV );
my $data = $signal_processor->getSignalData(
    { symbol => $symbols_txt, tf => $timeframe, expr => $expr, debug => $debug } );

print Dumper ( \$data );
