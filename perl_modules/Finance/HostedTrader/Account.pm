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

##Specific to the simulator account
use Storable;
=item C<simulatedTime>


=cut
has simulatedTime => (
    is     => 'rw',
    isa    => 'Str',
    required=>1,
);

=item C<expressionParser>


=cut
has expressionParser => (
    is     => 'ro',
    isa    => 'Finance::HostedTrader::ExpressionParser',
    required=>1,
);


##These should exist everywhere, regardless of broker
=item C<username>


=cut
has username => (
    is     => 'ro',
    isa    => 'Str',
    required=>1,
);

=item C<password>


=cut
has password => (
    is     => 'ro',
    isa    => 'Str',
    required=>1,
);

=item C<positions>


=cut
has positions => (
    is     => 'ro',
    isa    => 'HashRef[Finance::HostedTrader::Position]',
    builder => '_empty_hash',
    required=>0,
);

=item C<getMovePerPoint>


=cut
sub getMovePerPoint {
    my ($self) = @_;

    my $ep = $self->expressionParser;
    my $data = $ep->getIndicatorData( {
        symbol  => 'GBPUSD',
        tf      => 'min',
        fields  => 'datetime, close',
        maxLoadedItems => 1,
        endPeriod => $self->simulatedTime,
        debug => 0,
    } );
    return 1 / $data->[0]->[1];
}

sub getMultiplier {
    my ($self, $symbol) = @_;
    return 100 if ($symbol =~ /JPY/);
    return 10000;
}

=item C<getPosition>

=item C<getBalance>


=cut
sub getBalance {
    my ($self) = @_;

    return 15000;
}

=item C<getPosition>


=cut
sub getPosition {
    my ($self, $symbol) = @_;

    my $position = $self->positions->{$symbol};

    if (!defined($position)) {
        $position = Finance::HostedTrader::Position->new( symbol => $symbol);
        $self->positions->{$symbol} = $position;
    }

    return $position;
}

sub marketOrder {
    my ($self, $symbol, $size, $direction) = @_;

    my $ep = $self->expressionParser;
    my $data = $ep->getIndicatorData( {
        symbol  => $symbol,
        tf      => 'min',
        fields  => 'datetime, close',
        maxLoadedItems => 1,
        endPeriod => $self->simulatedTime,
        debug => 0,
    } );

    my ($datetime, $price);
    ($datetime, $price) = @{ $data->[0] } if ( defined($data) );
    die('market order failed') unless(defined($datetime) && defined($price));

    my $trade = Finance::HostedTrader::Trade->new(
                direction => $direction,
                symbol => $symbol,
                openDate => $datetime,
                openPrice => $price,
                size => $size,
            );

    my $position = $self->getPosition($trade->symbol);
    $position->addTrade($trade);
}

sub _getfilename {
    my ($self) = @_;

    return '/tmp/' . $self->{username} . $self->{password};
}

sub storePositions {
    my ($self) = @_;

    my $filename = $self->_getfilename;
    store $self->{positions}, $filename;
}

sub _empty_hash {
    return {};
}

sub BUILD {
    my $self = shift;

    my $filename = $self->_getfilename;
    return if (! -f $filename);
    $self->{positions} = retrieve($filename);
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
