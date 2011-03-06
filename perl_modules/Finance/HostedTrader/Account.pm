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
use Moose::Util::TypeConstraints;
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
    required=>0,
);

=item C<password>


=cut
has password => (
    is     => 'ro',
    isa    => 'Str',
    required=>0,
);

=item C<accountType>


=cut
#enum 'FXCMOrder2GOAccountType' => qw(DEMO REAL);
#has accountType => (
#    is     => 'ro',
#    isa    => 'FXCMOrder2GOAccountType',
#    required=>1,
#);

=item C<address>

The server address to connect to

=cut
has address => (
    is      => 'ro',
    isa     => 'Str',
    required=> 1,
);

=item C<port>

The server port to connect to

=cut
has port => (
    is      => 'ro',
    isa     => 'Int',
    required=> 1,
    default => 1500,
);

=item C<positions>


=cut
has positions => (
    is     => 'ro',
    isa    => 'HashRef[Finance::HostedTrader::Position]',
    builder => '_empty_hash',
    required=>0,
);


=item C<getNav>


=cut
sub getNav {
    my ($self) = @_;

    my $s = FXCMServer->new( address => $self->address, port => $self->port );
    return $s->nav();
}

=item C<getPosition>


=cut
sub getPosition {
my ($self, $symbol) = @_;

my $trades;

{
my $s = FXCMServer->new( address => $self->address, port => $self->port );
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
    my $s = FXCMServer->new( address => $self->address, port => $self->port );

    return $s->openMarket(@_);
}

=item C<closeTrades>


=cut
sub closeTrades {
    my ($self, $symbol, $direction) = @_;

    my $position = $self->getPosition($symbol);
    my $s = FXCMServer->new( address => $self->address, port => $self->port );
    foreach my $trade (@{ $position->trades }) {
        next if ($trade->direction ne $direction);
        $s->closeMarket($trade->id, $trade->size);
    }
}

=item C<closeMarket>


=cut
sub closeMarket {
    my $self = shift;
    my $s = FXCMServer->new( address => $self->address, port => $self->port );

    return $s->closeMarket(@_);
}

=item C<getAsk>


=cut
sub getAsk {
    my $self = shift;
    my $symbol = shift;

    my $s = FXCMServer->new( address => $self->address, port => $self->port );

#TODO: Need to be based on the symbols available in the account provider instead of based on FXCM
    if ($symbol eq 'GBPCAD') {
        return $s->getAsk('GBPUSD') * $s->getAsk('USDCAD');
    } else {
        return $s->getAsk($symbol);
    }
}

=item C<getBid>


=cut
sub getBid {
    my $self = shift;
    my $symbol = shift;

    my $s = FXCMServer->new( address => $self->address, port => $self->port );

#TODO: Need to be based on the symbols available in the account provider instead of based on FXCM
    if ($symbol eq 'GBPCAD') {
        return $s->getBid('GBPUSD') * $s->getBid('USDCAD');
    } else {
        return $s->getBid($symbol);
    }
}

=item C<converToBaseCurrency>

=cut

sub convertToBaseCurrency {
    my ($self, $amount, $currentCurrency, $bidask) = @_;
    $bidask = 'ask' if (!$bidask);

    my $baseCurrency = $self->getBaseCurrency();

    return $amount if ($baseCurrency eq $currentCurrency);
    my $pair = $baseCurrency . $currentCurrency;
    if ($bidask eq 'ask') {
        return $amount / $self->getAsk($pair);
    } elsif ($bidask eq 'bid') {
        return $amount / $self->getBid($pair);
    } else {
        die("Invalid value in bidask argument: '$bidask'");
    }
}

=item C<getBaseCurrency>

=cut
sub getBaseCurrency {
    my ($self) = @_;
    return 'GBP'; #TODO

}

=item C<getBaseUnit>


=cut
sub getBaseUnit {
    my $self = shift;
    my $s = FXCMServer->new( address => $self->address, port => $self->port );

    return $s->baseUnit(@_);
}

=item C<convertBaseUnit>

=cut
sub convertBaseUnit {
    my ($self, $symbol, $amount) = @_;
    my $baseUnit = $self->getBaseUnit($symbol);

    return int($amount / $baseUnit) * $baseUnit;
}

sub _getCurrentTrades {
    my $self = shift;
#Call FXCMServer from limited scope
#so that we release the TCP connection
#to the single threaded server
#as soon as possible
    my $s = FXCMServer->new( address => $self->address, port => $self->port );
    return $s->getTrades();
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
