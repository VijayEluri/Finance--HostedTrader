#!/usr/bin/perl
=head1 NAME

Outputs the value of an indicator against all known symbols


=head1 SYNOPSIS

    eval.pl [--timeframe=tf] [--verbose] [--symbols=s] [--debug] [--max-loaded-items=i] [--max-display-items=i] expr


=head1 DESCRIPTION

Sample expressions:

rsi(close,14)

ema(close,21)


=head2 OPTIONS

=over 12

=item C<--timeframe=tf>

Required argument. Specifies a single timeframe for which
synthetic data will be created.

tf can be a valid integer timeframe as defined in L<Finance::HostedTrader::Datasource>

=item C<--symbols=s>

Comma separated list of symbols for which to run the indicator against.
If not supplied, defaults to the list entry in the config file item "symbols.synthetic" and "symbols.natural".

=item C<--help>

Display usage information.

=item C<--debug>

Debug output.

=item C<--max-loaded-items=i>

Number of database records to load. Defaults to 1000 which should be enough to calculate any indicator.

=item C<--max-display-items=i>

Number of indicator periods to display. Defaults to one (eg: only display the indicator value today)

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

use Finance::HostedTrader::Config;
use Finance::HostedTrader::ExpressionParser;

use Data::Dumper;
use Date::Manip;
use Getopt::Long;
use Pod::Usage;

my ( $timeframe, $max_loaded_items, $symbols_txt, $debug, $help, $startPeriod, $endPeriod ) =
  ( 'day', 1000, '', 0, 0, '90 days ago', 'today' );

GetOptions(
    "timeframe=s"         => \$timeframe,
    "debug"               => \$debug,
    "symbols=s"           => \$symbols_txt,
    "max-loaded-items=i"  => \$max_loaded_items,
    "start=s" => \$startPeriod,
) || pod2usage(2);
pod2usage(1) if ($help);

my $cfg               = Finance::HostedTrader::Config->new();
my $signal_processor = Finance::HostedTrader::ExpressionParser->new();

my $symbols = $cfg->symbols->natural;

$symbols = [ split( ',', $symbols_txt ) ] if ($symbols_txt);


my @signals = (
'close > previous(max(close,89),1)',
'low < previous(min(close,89),1)',
);

foreach my $signal (@signals) {
print "$signal\n----------------------\n";
foreach my $symbol ( @{$symbols} ) {
    my $data = $signal_processor->getSignalData(
        {
            'expr'            => $signal,
            'symbol'          => $symbol,
            'tf'              => $timeframe,
            'maxLoadedItems'  => $max_loaded_items,
            'startPeriod'     => UnixDate($startPeriod, '%Y-%m-%d %H:%M:%S'),
            'endPeriod'       => UnixDate($endPeriod, '%Y-%m-%d %H:%M:%S'),
            'debug'           => 0,
        }
    );
    print $symbol, ' - ', Dumper(\$data) if (scalar(@$data));
}
}
