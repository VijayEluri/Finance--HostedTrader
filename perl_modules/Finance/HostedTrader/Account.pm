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
use FXCMServer;


use YAML::Syck;
use Data::Dumper;

YAML::Syck->VERSION( '0.70' );


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


=item C<getBalance>


=cut
sub getBalance {
    my ($self) = @_;

    return 10000;
}

=item C<getPosition>


=cut
sub getPosition {
my ($self, $symbol) = @_;

my $trades;

{
my $s = FXCMServer->new();
$trades = $s->getTrades();
#$s will go out of scope and close the TCP connection to the single threaded server
}

my %positions=();

    $self->{positions} = {};
    foreach my $trade_data (@$trades) {
        my $trade = Finance::HostedTrader::Trade->new(
            $trade_data
        );

        my $position = $self->_getPosition($trade->symbol);
        $position->addTrade($trade);
    }

    return $self->_getPosition($symbol);
}

=item C<openMarket>


=cut
sub openMarket {
    my $self = shift;
    my $s = FXCMServer->new();

    return $s->openMarket(@_);
}

=item C<closeTrades>


=cut
sub closeTrades {
    my ($self, $symbol) = @_;

    my $position = $self->getPosition($symbol);
    my $s = FXCMServer->new();
    foreach my $trade (@{ $position->trades }) {
        $s->closeMarket($trade->id, $trade->size);
    }
}

=item C<closeMarket>


=cut
sub closeMarket {
    my $self = shift;
    my $s = FXCMServer->new();

    return $s->closeMarket(@_);
}

=item C<getAsk>


=cut
sub getAsk {
    my $self = shift;
    my $s = FXCMServer->new();

    return $s->getAsk(@_);
}

=item C<getBid>


=cut
sub getBid {
    my $self = shift;
    my $s = FXCMServer->new();

    return $s->getBid(@_);
}


sub _empty_hash {
    return {};
}


sub _getPosition {
    my ($self, $symbol) = @_;

    my $position = $self->positions->{$symbol};

    if (!defined($position)) {
        $position = Finance::HostedTrader::Position->new( symbol => $symbol);
        $self->positions->{$symbol} = $position;
    }
    return $position;
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
