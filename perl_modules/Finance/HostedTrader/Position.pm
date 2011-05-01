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
    isa    => 'HashRef[Finance::HostedTrader::Trade]',
    builder => '_empty_hash',
    required=>0,
);

=back

=head2 Methods

=over 12

=item C<addTrade($trade)>

Adds the L<Finance::HostedTrader::Trade> object to this position.

Dies if another trade object with the same ID has already been added before
Dies if the symbol of $trade is different than the symbol of this position object instance

=cut
sub addTrade {
    my ($self, $trade) = @_;

    die("Trade has symbol " . $trade->symbol . " but position has symbol " . $self->symbol ) if ($self->symbol ne $trade->symbol);
    die("Trade already exists in position") if (exists($self->trades->{$trade->id}));
    $self->trades->{$trade->id} = $trade;
}

=item C<deleteTrade($id)>
=cut
sub deleteTrade {
    my $self = shift;
    my $tradeID = shift;
    
    delete $self->trades->{$tradeID};    
}

=item C<getTrade($id)>
=cut
sub getTrade {
    my $self = shift;
    my $id = shift;
    
    return $self->trades->{$id};
}

=item C<numOpenTrades()>
    Returns the number of open trades in this position
=cut
sub numOpenTrades {
    my $self = shift;
    
    return scalar(keys(%{$self->trades}));    
}

=item C<getTradeList()>
    Returns a reference to a list of trades in this position.
    There is no particular order in the returned data.
=cut
sub getTradeList {
    my $self = shift;
    
    my @trades = values(%{$self->trades});
    return \@trades;
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

    foreach my $trade (@{ $self->getTradeList }) {
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
    foreach my $trade (@{$self->getTradeList}) {
        $pl += $trade->pl;
    }
    return $pl
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

L<Finance::HostedTrader::Trade>

=cut
