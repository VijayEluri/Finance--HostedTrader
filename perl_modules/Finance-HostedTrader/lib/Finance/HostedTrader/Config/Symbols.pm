package Finance::HostedTrader::Config::Symbols;

# ABSTRACT: Finance::HostedTrader::Config::Symbols - DB Configuration for the Finance::HostedTrader platform

=head1 SYNOPSIS

    use Finance::HostedTrader::Config::Symbols;
    my $obj = Finance::HostedTrader::Config::Symbols->new(
                    'natural'   => ['AUDUSD', 'USDJPY'],
                    'synthetic' => ['AUDJPY'],
                );
=cut

use strict;
use warnings;
use Moose;

=attr C<natural>

Returns a list of natural symbols.
Natural symbols originate from the datasource, as opposed to synthetic symbols which are calculated based on natural symbols

Eg: AUDJPY can be synthetically calculated based on AUDUSD and USDJPY

=cut

has natural => (
    is     => 'ro',
    isa    => 'ArrayRef[Str]',
    required=>1,
);

=attr C<synthetic>

Returns a list of synthetic symbols.

See the description for natural symbols.

=cut


sub _around_symbols {
    my $orig = shift;
    my $self = shift;

    return $self->$orig() if @_; #Call the Moose generated setter if this is a set call (actually because the attributes are read-only we'll never have a set call, but just in case it changes later)

    # If it is a get call, call the Moose generated getter
    my $value = $self->$orig();
    return $value if (defined($value));
    return [];
}

has synthetic => (
    is     => 'ro',
    isa    => 'Maybe[ArrayRef[Str]]',
    builder => '_build_synthetic',
    required=>0,
);
#register method modifier so that undef values can be converted to empty lists
around 'synthetic' => \&_around_symbols;

sub _build_synthetic {
    return [];
}

=method C<all>

Returns a list of all symbols, natural and synthetic.

=cut
sub all {
    my $self = shift;
    return [ @{ $self->natural }, @{ $self->synthetic } ];

}

__PACKAGE__->meta->make_immutable;
1;

=head1 SEE ALSO

L<Finance::HostedTrader::Config>

=cut
