package Finance::HostedTrader::Config::Symbols;
=head1 NAME

    Finance::HostedTrader::Config::Symbols - DB Configuration for the Finance::HostedTrader platform

=head1 SYNOPSIS

    use Finance::HostedTrader::Config::Symbols;
    my $obj = Finance::HostedTrader::Config::Symbols->new(
                    'natural'   => ['AUDUSD', 'USDJPY'],
                    'synthetic' => ['AUDJPY'],
                );

=head1 DESCRIPTION


=head2 METHODS

=over 12

=cut

use strict;
use warnings;
use Moose;

=item C<natural>

Returns a list of natural symbols.
Natural symbols originate from the datasource, as opposed to synthetic symbols which are calculated based on natural symbols

Eg: AUDJPY can be synthetically calculated based on AUDUSD and USDJPY

=cut

has natural => (
    is     => 'ro',
    isa    => 'ArrayRef[Str]',
    required=>1,
);

=item C<synthetic>

Returns a list of synthetic symbols.

See the description for natural symbols.

=cut

has synthetic => (
    is     => 'ro',
    isa    => 'Maybe[ArrayRef[Str]]',
    builder => '_build_synthetic',
    required=>0,
);

sub _build_synthetic {
    return [];
}

=item C<all>

Returns a list of all symbols, natural and synthetic.

=cut
sub all {
    my $self = shift;
    return [ @{ $self->natural }, @{ $self->synthetic } ];

}

__PACKAGE__->meta->make_immutable;
1;

=back


=head1 LICENSE

This is released under the MIT license. See L<http://www.opensource.org/licenses/mit-license.php>.

=head1 AUTHOR

Joao Costa - L<http://zonalivre.org/>

=head1 SEE ALSO

L<Finance::HostedTrader::Config>

=cut
