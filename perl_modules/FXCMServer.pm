package FXCMServer;
=head1 NAME

    FXCMServer - Interface to the FXCM broker

=head1 SYNOPSIS

    use FXCMServer;
    my $s = FXCMServer->new();
    print $s->getAsk('EURUSD');
    print $s->getBid('EURUSD');

    my ($openOrderID, $price) = $s->openMarket('EURUSD', 'long', 100000);
    my $trades = $s->getTrades();

    my $tradeID = $trades->[0]->{ID};
    my $closeOrderID = $s->closeMarket($tradeID, 100000);

=head1 DESCRIPTION

Interfaces with the FXCM Order2Go API.
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
use IO::Socket;
use IO::Select;
use YAML::Syck;
use Finance::HostedTrader::Trade;

use constant CONNECT_TIMEOUT => 10;
use constant READ_TIMEOUT => 15;

=back

=head2 Methods

=over 12

=cut
sub BUILD {
    my $self = shift;
    my $sock = IO::Socket::INET->new(
                    PeerAddr => '127.0.0.1',
                    PeerPort => '1500',
                    Proto    => 'tcp',
                    Timeout  => CONNECT_TIMEOUT,
                    ) or die($!);
    $sock->autoflush(1);
    $self->{_sock} = $sock;
}

=item C<getTrades()>

Returns a list of opened trades in the account

=cut
sub getTrades {
    my ($self) = @_;
    my $yml = $self->_sendCmd('trades');

    return if (!$yml);
    my $data = YAML::Syck::Load( $yml ) || die("Invalid yaml: $!");
    return $data;
}

=item C<getAsk($symbol)>

Returns the current ask(long) price for $symbol

=cut

sub getAsk {
    my ($self, $symbol) = @_;

    return $self->_sendCmd("ask $symbol");
}

=item C<getBid($symbol)>

Returns the current bid(short) price for $symbol

=cut

sub getBid {
    my ($self, $symbol) = @_;

    return $self->_sendCmd("bid $symbol");
}

=item C<openMarket($symbol, $direction, $amount>

Opens a trade in $symbol at current market price.

$direction can be either 'long' or 'short'

In FXCM, $amount needs to be a multiple of 10.000

Returns a list containing two elements:

$tradeID - This can be passed to closeMarket. It can also be retrieved via getTrades
$price   - The price at which the trade was executed.

=cut

sub openMarket {
    my ($self, $symbol, $direction, $amount) = @_;

    my $data = $self->_sendCmd("openmarket $symbol $direction $amount");
    return split(/ /, $data);
}

=item C<closeMarket($tradeID, $amount)>

Closes a trade at current market price.

$tradeID is returned when calling openMarket(). It can also be retrieved via getTrades().

Returns $closedTradeID

=cut

sub closeMarket {
    my ($self, $tradeID, $amount) = @_;

    return $self->_sendCmd("closemarket $tradeID $amount");
}

=item C<baseUnit($symbol)>

Returns the base unit at which the symbol trades.
Eg, if baseUnit=10000, the symbol can only trade in multiples of 10000 (15000 would be an invalid trade size).

=cut

sub baseUnit {
    my ($self, $symbol) = @_;

    return $self->_sendCmd("baseunit $symbol");
}

sub nav {
    my ($self, $symbol) = @_;

    return $self->_sendCmd("nav");
}

sub _sendCmd {
    my ($self, $cmd) = @_;
    my $sock = $self->{_sock};

    my $select = IO::Select->new($sock);

    print $sock $cmd."\n";

    if ( $select->can_read(READ_TIMEOUT) ) {
        $/="||THE_END||";
        my $data = <$sock>;
        die("Server returned no response") if (!$data);
        chomp($data);

        my ($code, $msg) = split(/ /, $data, 2);
        if ($code == 200) {
            return $msg;
        } elsif ($code == 500) {
            die("Internal Error: $msg");
        } elsif ($code == 404) {
            die("Command not found: $msg");
        } else {
            die("Unknown return code: $code, msg=$msg");
        }
        return $msg;
    } else {
        die("Timeout reading from server (cmd=$cmd)");
    }

}

sub DEMOLISH {
    my $self = shift;

    my $sock = $self->{_sock};
    close($sock);
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
