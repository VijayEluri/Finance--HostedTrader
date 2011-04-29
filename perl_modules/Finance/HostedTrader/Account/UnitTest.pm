package Finance::HostedTrader::Account::UnitTest;

use Moose;
extends 'Finance::HostedTrader::Account';

use Moose::Util::TypeConstraints;
use Finance::HostedTrader::Trade;
use Date::Manip;
use Time::HiRes;


=head1 NAME

    Finance::HostedTrader::Account::UnitTest - Interface to the UnitTest broker

=head1 SYNOPSIS

    use UnitTest;
    my $s = Finance::HostedTrader::Account::UnitTest->new( address => '127.0.0.1', port => 1500 );
    print $s->getAsk('EURUSD');
    print $s->getBid('EURUSD');

    my ($openOrderID, $price) = $s->openMarket('EURUSD', 'long', 100000);
    my $closeOrderID = $s->closeMarket($openOrderID, 100000);

=head1 DESCRIPTION



=head2 Properties

=over 12

=item C<startDate>

=cut
has startDate => (
    is     => 'ro',
    isa    => 'Str',
    required=>1,
    default => '2 weeks ago',
);

=item C<endDate>

=cut
has endDate => (
    is     => 'ro',
    isa    => 'Str',
    required=>1,
    default => 'now',
);

=item C<interval>

=cut
has interval => (
    is     => 'ro',
    isa    => 'Str',
    required=>1,
    default => '240 seconds',
);

=back

=head2 Methods

=over 12

=cut

sub BUILD {
    my $self = shift;

    $self->{_now} = UnixDate($self->startDate, '%Y-%m-%d %H:%M:%S');
}

sub refreshPositions {
    my $self = shift;
# positions are kept in memory
# Calculate current p/l for each open trade
    my $positions = $self->{_positions};
    foreach my $key (keys(%{$positions})) {
        foreach my $trade (@{ $positions->{$key}->trades }) {
            my $symbol = $trade->symbol;
            my $rate = ($trade->direction eq "long" ? $self->getAsk($symbol) : $self->getBid($symbol));
            my $base = $self->getSymbolBase($symbol);
            my $pl = ($rate - $trade->openPrice) * $trade->size;

            if ($base ne "GBP") { # TODO: should not be hardcoded that account is based on GBP
                $pl /= $self->getAsk("GBP$base"); # TODO: this won't work for all cases( eg, if base is EUR)
            }
            $trade->pl($pl);
        }
    }

}

sub getAsk {
    my ($self, $symbol) = @_;

    return $self->getIndicatorValue($symbol, 'close', { timeframe => '5min', maxLoadedItems => 1 });
}

sub getBid {
    my ($self, $symbol) = @_;

    return $self->getIndicatorValue($symbol, 'close', { timeframe => '5min', maxLoadedItems => 1 });
}

sub openMarket {
    my ($self, $symbol, $direction, $amount) = @_;

    my $id = $$ . Time::HiRes::time();
    my $rate = ($direction eq "long" ? $self->getAsk($symbol) : $self->getBid($symbol));

    my $trade = Finance::HostedTrader::Trade->new(
            id          => $id,
            symbol      => $symbol,
            direction   => $direction,
            openDate    => UnixDate($self->{_now}, '%Y-%m-%d %H:%M:%S'),
            openPrice   => $rate,
            size        => $amount,
    );

    my $position = $self->getPosition($symbol);
    $position->addTrade($trade);
    $self->{_positions}->{$symbol} = $position;

    return ($id, $rate);
}

sub closeMarket {
    my ($self, $tradeID, $amount) = @_;
die("TODO closeMarket");
}

sub getBaseUnit {
    my ($self, $symbol) = @_;

    return 10000;
}

sub getNav {
    my $self = shift;

    return $self->balance() + $self->pl();
}

sub balance {
    my ($self) = @_;
    return 50000;
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
            'simulatedNowValue' => $self->{_now},
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
                endPeriod => $self->{_now},
    } );

    return $value->[0]->[1];
}

sub waitForNextTrade {
    my ($self) = @_;

    my ($sec, $min, $hr, $day, $month, $year, $weekday) = gmtime($self->getServerEpoch());
    my $interval = ($weekday != 0 && $weekday != 6 ? $self->interval : '3 hours');
    $self->{_now} = UnixDate(DateCalc($self->{_now}, $interval), '%Y-%m-%d %H:%M:%S');
}

sub getServerEpoch {
    my $self = shift;

    return UnixDate($self->{_now}, '%s');
}

1;

=back

=head1 LICENSE

This is released under the MIT license. See L<http://www.opensource.org/licenses/mit-license.php>.

=head1 AUTHOR

Joao Costa - L<http://zonalivre.org/>

=head1 SEE ALSO

L<Server.exe>

=cut
