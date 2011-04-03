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
use Finance::HostedTrader::ExpressionParser;
use Finance::HostedTrader::Position;
use Finance::HostedTrader::Trade;


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

=item C<positions>


=cut
has positions => (
    is     => 'ro',
    isa    => 'HashRef[Finance::HostedTrader::Position]',
    builder => '_empty_hash',
    required=>0,
);

sub BUILD {
    my $self = shift;

    $self->{_signal_processor} = Finance::HostedTrader::ExpressionParser->new();
}

sub checkSignal {
    my ($self, $symbol, $signal_definition, $signal_args) = @_;

    return $self->{_signal_processor}->checkSignal(
        {
            'expr' => $signal_definition, 
            'symbol' => $symbol,
            'tf' => $signal_args->{timeframe},
            'maxLoadedItems' => $signal_args->{maxLoadedItems},
            'period' => $signal_args->{period},
            'debug' => $signal_args->{debug},
        }
    );
}

sub getIndicatorValue {
    my ($self, $symbol, $indicator, $args) = @_;

    my $value = $self->{_signal_processor}->getIndicatorData( {
                symbol  => $symbol,
                tf      => $args->{timeframe},
                fields  => 'datetime, ' . $indicator,
                maxLoadedItems => $args->{maxLoadedItems},
                numItems => 1,
                debug => $args->{debug},
    } );

    return $value->[0]->[1];
}

sub waitForNextTrade {
    my ($self, $system) = @_;

    sleep(20);
}

=item C<getNav>

Return the current net asset value in the account

=cut
sub getNav {
    die("overrideme");
}

=item C<getPosition>


=cut
sub getPosition {
    my ($self, $symbol) = @_;

    my $positions = $self->positions;
    return $positions->{$symbol} if (exists $positions->{$symbol});
    return Finance::HostedTrader::Position->new( symbol => $symbol );
}

=item C<openMarket>


=cut
sub openMarket {
    die("overrideme");
}

=item C<closeTrades>


=cut
sub closeTrades {
    my ($self, $symbol, $direction) = @_;

    my $position = $self->getPosition($symbol);
    foreach my $trade (@{ $position->trades }) {
        next if ($trade->direction ne $direction);
        $self->closeMarket($trade->id, $trade->size);
    }
}

=item C<closeMarket>


=cut
sub closeMarket {
    die("overrideme");
}

=item C<getAsk>


=cut
sub getAsk {
    die("overrideme");
}

=item C<getBid>


=cut
sub getBid {
    die("overrideme");
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
    die("overrideme");
}

=item C<getBaseUnit>


=cut
sub getBaseUnit {
    die("overrideme");
}

=item C<convertBaseUnit>

=cut
sub convertBaseUnit {
    my ($self, $symbol, $amount) = @_;
    my $baseUnit = $self->getBaseUnit($symbol);

    return int($amount / $baseUnit) * $baseUnit;
}

=item C<getSymbolBase>

=cut
sub getSymbolBase {
    die("overrideme");
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
