package Finance::HostedTrader::Account;
=head1 NAME

    Finance::HostedTrader::Account - Trade object

=head1 SYNOPSIS

    use Finance::HostedTrader::Account;
    my $obj = Finance::HostedTrader::Account->new(
                );

=head1 DESCRIPTION


=head2 METHODS

=over 12

=cut

use strict;
use warnings;
use Moose;
use Finance::HostedTrader::Position;
use Finance::HostedTrader::Trade;

=item C<positions>


=cut
has positions => (
    is     => 'ro',
    isa    => 'HashRef[Finance::HostedTrader::Position]',
    builder => '_empty_hash',
    required=>0,
);


=item C<setPosition>


=cut
sub setPosition {
    my ($self, $symbol, $position) = @_;

    $self->positions->{$symbol} = $position;
}

=item C<getPosition>


=cut
sub getPosition {
    my ($self, $symbol) = @_;

    my $position = $self->positions->{$symbol};

    if (!defined($position)) {
        $position = Finance::HostedTrader::Position->new( symbol => $symbol);
        $self->setPosition($symbol, $position);
    }

    return $position;
}

=item C<addTrade>


=cut
sub addTrade {
    my ($self, $trade) = @_;

    my $position = $self->getPosition($trade->symbol);
    $position->addTrade($trade);
}

=item C<addPosition>


=cut
sub addPosition {
    my ($self, $symbol, $direction, $size) = @_;

    my $trade = Finance::HostedTrader::Trade->new(
                direction => $direction,
                symbol => $symbol,
                openDate => '2010-01-01',
                openPrice => 0.8800,
                size => $size,
            );

    $self->addTrade($trade);
}

=item C<closePosition>


=cut
sub closePosition {
    my ($self, $symbol) = @_;

    my $pos = $self->getPosition($symbol);
    $pos->close();
}

sub _empty_hash {
    return {};
}

__PACKAGE__->meta->make_immutable;
1;

=back


=head1 LICENSE

This is released under the MIT license. See L<http://www.opensource.org/licenses/mit-license.php>.

=head1 AUTHOR

Joao Costa - L<http://zonalivre.org/>

=head1 SEE ALSO

L<Finance::HostedTrader::Position>

=cut
