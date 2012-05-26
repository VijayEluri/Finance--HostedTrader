package Finance::HostedTrader::Position;

# ABSTRACT: Finance::HostedTrader::Position - Trade object

=head1 SYNOPSIS

    use Finance::HostedTrader::Position;
    my $obj = Finance::HostedTrader::Position->new(
                );

=cut

use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;

=attr C<symbol>


=cut
has symbol => (
    is     => 'ro',
    isa    => 'Str',
    required=>1,
);

=attr C<trades>


=cut
has trades => (
    is     => 'ro',
    isa    => 'HashRef[Finance::HostedTrader::Trade]',
    builder => '_empty_hash',
    required=>0,
);

=method C<addTrade($trade)>

Adds the L<Finance::HostedTrader::Trade> object to this position.

Dies if another trade object with the same ID has already been added before
Dies if the symbol of $trade is different than the symbol of this position object instance

=cut
sub addTrade {
    my ($self, $trade) = @_;
    my $self_symbol = $self->symbol;
    my $self_trades = $self->trades;
    my $trade_symbol = $trade->symbol;
    my $trade_id = $trade->id;

    die("Trade has symbol " . $trade->symbol . " but position has symbol " . $self_symbol ) if ($self_symbol ne $trade_symbol);
    die("Trade already exists in position") if (exists($self_trades->{$trade_id}));
    $self_trades->{$trade_id} = $trade;
}

=method C<deleteTrade($id)>
=cut
sub deleteTrade {
    my $self = shift;
    my $tradeID = shift;
    
    delete $self->trades->{$tradeID};    
}

=method C<getTrade($id)>
=cut
sub getTrade {
    my $self = shift;
    my $id = shift;
    
    return $self->trades->{$id};
}

=method C<getOpenTradeList()>
    Returns a reference to a list of trades in this position.
    There is no particular order in the returned data.
=cut
sub getOpenTradeList {
    my $self = shift;
    
    my @trades = values(%{$self->trades});
    return \@trades;
}

=method C<size()>

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

    foreach my $trade (@{ $self->getOpenTradeList }) {
        $size += $trade->size();
    }

    return $size;
}

=method C<averagePrice>

=cut
sub averagePrice {
    my ($self) = @_;
    
    my $size = 0;
    my $price = 0;

    foreach my $trade(@{ $self->getOpenTradeList }) {
        $size += $trade->size();
        $price += $trade->size() * $trade->openPrice();
    }

    return undef if ($size == 0);
    return $price / $size;
}

=method C<pl>

Calculate total profit/loss of a given position

=cut
sub pl {
    my ($self, $system) = @_;
    my $pl=0;
    foreach my $trade (@{$self->getOpenTradeList}) {
        $pl += $trade->pl;
    }
    return $pl
}

sub _empty_hash {
    return {};
}

__PACKAGE__->meta->make_immutable;
1;

=head1 SEE ALSO

L<Finance::HostedTrader::Trade>

=cut
