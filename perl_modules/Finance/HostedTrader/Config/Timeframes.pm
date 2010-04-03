package Finance::HostedTrader::Config::Timeframes;
=head1 NAME

    Finance::HostedTrader::Config::Timeframes - DB Configuration for the Finance::HostedTrader platform

=head1 SYNOPSIS

    use Finance::HostedTrader::Config::Timeframes;
    my $obj = Finance::HostedTrader::Config::Timeframes->new(
                    'dbhost'   => server_name,
                    'dbname'   => dbname,
                    'dbuser'   => dbuser,
                    'dbpasswd' => dbpasswd
                );

=head1 DESCRIPTION


=head2 METHODS

=over 12

=cut

use strict;
use warnings;
use Moose;

#List of available timeframes this module understands
my %timeframes = (
    'tick'  => 0,
    'sec'   => 1,
    '5sec'  => 5,
    '15sec' => 15,
    '30sec' => 30,
    'min'   => 60,
    '5min'  => 300,
    '15min' => 900,
    '30min' => 1800,
    'hour'  => 3600,
    '2hour' => 7200,
    '3hour' => 10800,
    '4hour' => 14400,
    'day'   => 86400,
    '2day'  => 172800,
    'week'  => 604800
);

#These two subs are used to make sure timeframe data is returned sorted
sub _around_timeframes {
    my $orig = shift;
    my $self = shift;

    return $self->$orig() if @_; #Call the Moose generated setter if this is a set call

    # If it is a get call, call the Moose generated getter and sort the items
    return $self->_sort_timeframes($self->$orig());

#Note that inverting the logic to initially store the sorted list
#instead of sorting in every call won't work because this does not get called
#at build time
}

sub _sort_timeframes {
my $self = shift;
my $values =shift;
use Data::Dumper;

    my @sorted =
      sort { int($a) <=> int($b) }
      ( @{ $values } );

return \@sorted;
}

=item C<natural>

Returns a list of natural timeframes.
Natural timeframes originate from the datasource, as opposed to synthetic timeframes which are calculated based on natural timeframes

Eg: The 2 hour timeframe can be derived from the 1 hour timeframe.

=cut
has natural => (
    is     => 'ro',
    isa    => 'ArrayRef[Str]',
    required=>1,
);
#register method modifier so the passed timeframe values can be sorted
around 'natural' => \&_around_timeframes;   

=item C<synthetic>

Returns a list of synthetic timeframes.

See the description for natural timeframes.

=cut

has synthetic => (
    is     => 'ro',
    isa    => 'Maybe[ArrayRef[Str]]',
    builder => '_build_synthetic',
    required=>0,
);
#register method modifier so the passed timeframe values can be sorted
around 'synthetic' => \&_around_timeframes;

sub _build_synthetic {
    return [];
}

=item C<all>

Returns a list of all timeframes, natural and synthetic, sorted by granularity.

Shorter timeframes will come first, eg: 1 minute will be before 1 hour

=cut
sub all {
    my $self = shift;

   return $self->_sort_timeframes( [ @{ $self->natural }, @{ $self->synthetic } ] );
}


1;

=back


=head1 LICENSE

This is released under the MIT license. See L<http://www.opensource.org/licenses/mit-license.php>.

=head1 AUTHOR

Joao Costa - L<http://zonalivre.org/>

=head1 SEE ALSO

L<Finance::HostedTrader::Config>

=cut
