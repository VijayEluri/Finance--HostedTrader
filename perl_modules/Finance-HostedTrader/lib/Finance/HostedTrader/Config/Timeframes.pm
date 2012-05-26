package Finance::HostedTrader::Config::Timeframes;

# ABSTRACT: Finance::HostedTrader::Config::Timeframes - DB Configuration for the Finance::HostedTrader platform

=head1 SYNOPSIS

    use Finance::HostedTrader::Config::Timeframes;
    my $obj = Finance::HostedTrader::Config::Timeframes->new(
                    natural => [60, 300],
                );
=cut

use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;

#List of available timeframes this module understands
#TODO finish missing date/time formats
my %timeframes = (
    'tick'  => [0, undef],
    'sec'   => [1, undef],
    '5sec'  => [5, undef],
    '15sec' => [15, undef],
    '30sec' => [30, undef],
    'min'   => [60, undef],
    '2min'  => [120, undef],
    '5min'  => [300, "CAST(CONCAT(year(datetime), '-', month(datetime), '-', day(datetime), ' ',  hour(datetime), ':', floor(minute(datetime) / 5) * 5, ':00') AS DATETIME)"],
    '15min' => [900, "CAST(CONCAT(year(datetime), '-', month(datetime), '-', day(datetime), ' ',  hour(datetime), ':', floor(minute(datetime) / 15) * 15, ':00') AS DATETIME)"],
    '30min' => [1800, "CAST(CONCAT(year(datetime), '-', month(datetime), '-', day(datetime), ' ',  hour(datetime), ':', floor(minute(datetime) / 30) * 30, ':00') AS DATETIME)"],
    'hour'  => [3600, "date_format(datetime, '%Y-%m-%d %H:00:00')"],
    '2hour' => [7200, "CAST(CONCAT(year(datetime), '-', month(datetime), '-', day(datetime), ' ',  floor(hour(datetime) / 2) * 2, ':00:00') AS DATETIME)"],
    '3hour' => [10800, "CAST(CONCAT(year(datetime), '-', month(datetime), '-', day(datetime), ' ',  floor(hour(datetime) / 3) * 3, ':00:00') AS DATETIME)"],
    '4hour' => [14400, "CAST(CONCAT(year(datetime), '-', month(datetime), '-', day(datetime), ' ',  floor(hour(datetime) / 4) * 4, ':00:00') AS DATETIME)"],
    'day'   => [86400, "date_format(datetime, '%Y-%m-%d 00:00:00')"],
    '2day'  => [172800, undef],
    'week'  => [604800, "date_format(date_sub(datetime, interval weekday(datetime)+1 DAY), '%Y-%m-%d 00:00:00')"],
);

enum 'TimeframeIDs' => qw(0 1 5 15 30 60 120 300 900 1800 3600 7200 10800 14400 86400 172800 604800);

#These two subs are used to make sure timeframe data is returned sorted
sub _around_timeframes {
    my $orig = shift;
    my $self = shift;

    return $self->$orig() if @_; #Call the Moose generated setter if this is a set call (actually because the attributes are read-only we'll never have a set call, but just in case it changes later)

    # If it is a get call, call the Moose generated getter and sort the items
    return $self->_sort_timeframes($self->$orig());

#Note that inverting the logic to initially store the sorted list
#instead of sorting in every call won't work because this does not get called
#at build time
}

sub _sort_timeframes {
my $self = shift;
my $values =shift;

    return [] if (!defined($values));
    my @sorted =
      sort { int($a) <=> int($b) }
      ( @{ $values } );

return \@sorted;
}

=attr C<natural>

Returns a list of natural timeframes.
Natural timeframes originate from the datasource, as opposed to synthetic timeframes which are calculated based on natural timeframes

Eg: The 2 hour timeframe can be derived from the 1 hour timeframe.

=cut
has natural => (
    is     => 'ro',
    isa    => 'ArrayRef[TimeframeIDs]',
    required=>1,
);
#register method modifier so the passed timeframe values can be sorted
around 'natural' => \&_around_timeframes;   

=attr C<synthetic>

Returns a list of synthetic timeframes.  If not defined (either by omission or by explicitly setting it to undef), returns an empty list when accessed.

See the description for natural timeframes.

=cut

has synthetic => (
    is     => 'ro',
    isa    => 'Maybe[ArrayRef[TimeframeIDs]]',
    builder => '_build_synthetic',
    required=>0,
);
#register method modifier so the passed timeframe values can be sorted and undef values converted to empty lists
around 'synthetic' => \&_around_timeframes;

sub _build_synthetic {
    return [];
}

=method C<all>

Returns a list of all timeframes, natural and synthetic, sorted by granularity.

Shorter timeframes will come first, eg: 1 minute will be before 1 hour

=cut
sub all {
    my $self = shift;

   return $self->_sort_timeframes( [ @{ $self->natural }, @{ $self->synthetic } ] );
}

=method C<getTimeframeID>

Returns the numeric timeframe id from the stringified timeframe
eg: 
my $tf = $self->getTimeframeID('day');

=cut
sub getTimeframeID {
    my ( $self, $name ) = @_;
    return $timeframes{$name}->[0];
}

=method C<getTimeframeName>

Returns the stringified timeframe name for the given
timeframe ID

eg:
my $tf = $self->getTimeframeName(60);
=cut
sub getTimeframeName {
    my ( $self, $id ) = @_;
    grep { return $_ if $timeframes{$_}->[0] == $id } keys(%timeframes);
}

=method C<getTimeframeFormat>
=cut
sub getTimeframeFormat {
    my ($self, $name) = @_;
    
    return $timeframes{$name}->[1];
}

__PACKAGE__->meta->make_immutable;
1;

=head1 SEE ALSO

L<Finance::HostedTrader::Config>

=cut
