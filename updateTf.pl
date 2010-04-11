#!/usr/bin/perl
=head1 updateTf.pl

Generates synthetic timeframes

=head1 SYNOPSIS

    updateTf.pl [--start="5 years ago"] [--end=today] [--symbols=s] [--timeframes=tf] [--available-timeframe=s] [--verbose]

=head1 DESCRIPTION


=head2 OPTIONS

=over 12

=item C<--start=s>

The starting date to convert from. See L<Date::Manip> for acceptable date formats.

=item C<--end=s>

The ending date to convert to. See L<Date::Manip> for acceptable date formats.

=item C<--symbols=s>

Comma separated list of symbols for which to create synthetic data.
If not supplied, defaults to the list entries in the config file items "symbols.natural" and "symbols.synthetic".

=item C<--timeframes=tf>

Comma separated list of timeframes for which to create synthetic data.
If not supplied, defaults to the list entries in the config file items "timeframes.synthetic".

tf can be a valid integer timeframe as defined in L<Finance::HostedTrader::Datasource>

=item C<--available-timeframes=s>

The base timeframe to use for conversion. Defaults to one minute timeframe which is crap.

TODO: Make this default to the highest natural timeframe which is smaller than the target timeframe.

TODO: Or maybe even use existing synthetic timeframes if they have already been converted here

if converting to multiple timeframes the code will try to use newly converted tfs

Use timeframe name instead of numeric code

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
L<Date::Manip>

=cut

use strict;
use warnings;

use Finance::HostedTrader::Datasource;

use Date::Manip;
use Getopt::Long;
use Pod::Usage;

my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
  localtime( time - 24 * 60 * 60 );
my ( $start_date, $end_date ) = ( '0001-01-01', '9998-12-31' );
my ( $symbols_txt, $timeframe_txt );
my $available_timeframe = 'min';
my $verbose             = 0;
my $help             = 0;

my $result = GetOptions(
    "start=s",               \$start_date,
    "end=s",                 \$end_date,
    "symbols=s",             \$symbols_txt,
    "timeframes=s",           \$timeframe_txt,
    "available-timeframe=s", \$available_timeframe,
    "verbose",               \$verbose,
    "help",               \$help,
) || pod2usage(2);
pod2usage(1) if ($help);

$start_date = UnixDate( $start_date, "%Y-%m-%d %H:%M:%S" )
  or die("Cannot parse $start_date");
$end_date = UnixDate( $end_date, "%Y-%m-%d %H:%M:%S" )
  or die("Cannot parse $end_date");

my $db = Finance::HostedTrader::Datasource->new();
my $cfg = $db->cfg;
my $symbols;
if ( !defined($symbols_txt) ) {
    $symbols = $cfg->symbols->all();
}
elsif ( $symbols_txt eq 'natural' ) {
    $symbols = $cfg->symbols->natural();
}
elsif ( $symbols_txt eq 'synthetics' ) {
    $symbols = $cfg->symbols->synthetics();
}
else {
    $symbols = [ split( ',', $symbols_txt ) ] if ($symbols_txt);
}

my $tfs = $cfg->timeframes->synthetic();
$tfs = [ split( ',', $timeframe_txt ) ] if ($timeframe_txt);

$available_timeframe = $cfg->timeframes->getTimeframeID($available_timeframe);

##TODO: Bug - This won't work if it tries to convert from 2hour to 3hour timeframe
#This code assumes timeframes are sorted (which is ok)
#and the previous timeframe can build the current one (which is not always the case)
foreach my $tf ( @{$tfs} ) {
    next if ( $tf == $available_timeframe );
    foreach my $symbol ( @{$symbols} ) {
        print "$symbol\t$available_timeframe\t$tf\t$start_date\t$end_date\n"
          if ($verbose);
        $db->convertOHLCTimeSeries( $symbol, $available_timeframe, $tf,
            $start_date, $end_date );
    }
    $available_timeframe = $tf;
}
