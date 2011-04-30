package Finance::HostedTrader::Position;
=head1 NAME

    Finance::HostedTrader::Position - Trade object

=head1 SYNOPSIS

    use Finance::HostedTrader::Position;
    my $obj = Finance::HostedTrader::Position->new(
                );

=head1 DESCRIPTION


=head2 Properties

=over 12

=cut

use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;

=item C<symbol>


=cut
has symbol => (
    is     => 'ro',
    isa    => 'Str',
    required=>1,
);

=item C<trades>


=cut
has trades => (
    is     => 'ro',
    isa    => 'ArrayRef[Finance::HostedTrader::Trade]',
    builder => '_empty_list',
    required=>0,
);

=back

=head2 Methods

=over 12

=item C<addTrade($trade)>

Adds the L<Finance::HostedTrader::Trade> object to this position.

Dies if the symbol of $trade is different than the symbol of this position object instance.

=cut
sub addTrade {
    my ($self, $trade) = @_;

    die("Trade has symbol " . $trade->symbol . " but position has symbol " . $self->symbol ) if ($self->symbol ne $trade->symbol);
    push @{$self->trades}, $trade;
}

=item C<size()>

Returns the aggregate size of all trades in this position.

Eg1:
  short 10000
  long  20000

  size = 10000

Eg2:
  short 10000
  short 10000

  size = -20000
=cut
sub size {
    my ($self) = @_;

    my $size = 0;

    foreach my $trade (@{ $self->trades }) {
        if ($trade->direction eq 'long') {
            $size += $trade->size();
        } else {
            $size -= $trade->size();
        }
    }

    return abs($size);
}

=item C<pl>

Calculate total profit/loss of a given position

=cut
sub pl {
    my ($self, $system) = @_;
    my $pl=0;
    foreach my $trade (@{$self->trades}) {
        $pl += $trade->pl;
    }
    return $pl
}

sub _empty_list {
    return [];
}

__PACKAGE__->meta->make_immutable;
1;

=back


=head1 LICENSE

This is released under the MIT license. See L<http://www.opensource.org/licenses/mit-license.php>.

=head1 AUTHOR

Joao Costa - L<http://zonalivre.org/>

=head1 SEE ALSO

L<Finance::HostedTrader::Trade>

=cut
