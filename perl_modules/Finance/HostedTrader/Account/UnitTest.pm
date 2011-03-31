package Finance::HostedTrader::Account::UnitTest;
=head1 NAME

    Finance::HostedTrader::Account::UnitTest - Interface to the UnitTest broker

=head1 SYNOPSIS

    use UnitTest;
    my $s = Finance::HostedTrader::Account::UnitTest->new( address => '127.0.0.1', port => 1500 );
    print $s->getAsk('EURUSD');
    print $s->getBid('EURUSD');

    my ($openOrderID, $price) = $s->openMarket('EURUSD', 'long', 100000);
    my $trades = $s->getTrades();

    my $tradeID = $trades->[0]->{ID};
    my $closeOrderID = $s->closeMarket($tradeID, 100000);

=head1 DESCRIPTION

Interfaces with the UnitTest Order2Go API.
The Order2GO API is available as a windows COM object.

In order to run this under Linux, I've written a windows application (Server.exe)
in C++ which provides a proxy to Order2Go through sockets.

Server.exe can be run
on Linux under wine, and this module connects to a socket opened by Server.exe on
port 1500 to access the Order2Go API.


=head2 Properties

=over 12

=cut

use Moose;
extends 'Finance::HostedTrader::Account';

use Moose::Util::TypeConstraints;
use Finance::HostedTrader::Trade;
use Date::Manip;

=back

=head2 Methods

=over 12

=cut

sub BUILD {
    my $self = shift;

    $self->{_now} = UnixDate(DateCalc('now', '- 2 week'), '%Y-%m-%d %H:%M:%S');
}

=item C<getTrades()>

Returns a list of opened trades in the account

=cut
sub getTrades {
    my ($self) = @_;
 
    return [];
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

sub getNav {
    my ($self) = @_;
    return 50000;
}

sub getAsk {
    my ($self, $symbol) = @_;

    return $self->getIndicatorValue($symbol, 'close', { timeframe => '5min' });
}

sub getBid {
    my ($self, $symbol) = @_;

    return $self->getIndicatorValue($symbol, 'close', { timeframe => '5min' });
}

sub getBaseUnit {
    my ($self, $symbol) = @_;

    return 10000;
}

sub openMarket {
    my ($self, $symbol, $direction, $amount) = @_;
}

sub closeMarket {
    my ($self, $tradeID, $amount) = @_;

}

sub waitForNextTrade {
    my ($self, $system) = @_;

    $self->{_now} = UnixDate(DateCalc($self->{_now}, '30 seconds'), '%Y-%m-%d %H:%M:%S');
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
