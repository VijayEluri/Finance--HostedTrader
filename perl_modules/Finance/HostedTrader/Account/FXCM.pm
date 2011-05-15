package Finance::HostedTrader::Account::FXCM;
=head1 NAME

    Finance::HostedTrader::Account::FXCM - Interface to the FXCM broker

=head1 SYNOPSIS

    use FXCM;
    my $s = Finance::HostedTrader::Account::FXCM->new( address => '127.0.0.1', port => 1500 );
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
extends 'Finance::HostedTrader::Account';

use Moose::Util::TypeConstraints;
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
);

=item C<accountType>


=cut
#enum 'FXCMOrder2GOAccountType' => qw(DEMO REAL);
#has accountType => (
#    is     => 'ro',
#    isa    => 'FXCMOrder2GOAccountType',
#    required=>1,
#);

my %symbolMap = (
    AUDCAD => 'AUD/CAD',
    AUDCHF => 'AUD/CHF',
    AUDJPY => 'AUD/JPY',
    AUDNZD => 'AUD/NZD',
    AUDUSD => 'AUD/USD',
    AUS200 => 'AUS200',
    CADCHF => 'CAD/CHF',
    CADJPY => 'CAD/JPY',
    CHFJPY => 'CHF/JPY',
    CHFNOK => 'CHF/NOK',
    CHFSEK => 'CHF/SEK',
    EURAUD => 'EUR/AUD',
    EURCAD => 'EUR/CAD',
    EURCHF => 'EUR/CHF',
    EURDKK => 'EUR/DKK',
    EURGBP => 'EUR/GBP',
    EURJPY => 'EUR/JPY',
    EURNOK => 'EUR/NOK',
    EURNZD => 'EUR/NZD',
    EURSEK => 'EUR/SEK',
    EURTRY => 'EUR/TRY',
    EURUSD => 'EUR/USD',
    GBPAUD => 'GBP/AUD',
    GBPCAD => 'GBP/CAD',
    GBPCHF => 'GBP/CHF',
    GBPJPY => 'GBP/JPY',
    GBPNZD => 'GBP/NZD',
    GBPSEK => 'GBP/SEK',
    GBPUSD => 'GBP/USD',
    HKDJPY => 'HKD/JPY',
    NOKJPY => 'NOK/JPY',
    NZDCAD => 'NZD/CAD',
    NZDCHF => 'NZD/CHF',
    NZDJPY => 'NZD/JPY',
    NZDUSD => 'NZD/USD',
    SEKJPY => 'SEK/JPY',
    SGDJPY => 'SGD/JPY',
    TRYJPY => 'TRY/JPY',
    USDCAD => 'USD/CAD',
    USDCHF => 'USD/CHF',
    USDDKK => 'USD/DKK',
    USDHKD => 'USD/HKD',
    USDJPY => 'USD/JPY',
    USDMXN => 'USD/MXN',
    USDNOK => 'USD/NOK',
    USDSEK => 'USD/SEK',
    USDSGD => 'USD/SGD',
    USDTRY => 'USD/TRY',
    USDZAR => 'USD/ZAR',
    XAGUSD => 'XAG/USD',
    XAUUSD => 'XAU/USD',
    ZARJPY => 'ZAR/JPY',
    ESP35  => 'ESP35',
    FRA40  => 'FRA40',
    GER30  => 'GER30',
    HKG33  => 'HKG33',
    ITA40  => 'ITA40',
    JPN225 => 'JPN225',
    NAS100 => 'NAS100',
    SPX500 => 'SPX500',
    SUI30  => 'SUI30',
    SWE30  => 'SWE30',
    UK100  => 'UK100',
    UKOil  => 'UKOil',
    US30   => 'US30',
    USOil  => 'USOil',
);

=item C<refreshPositions()>


=cut
sub refreshPositions {
    my ($self) = @_;

    $self->{_positions} = {};
    my $yml = $self->_sendCmd('trades');

    return if (!$yml);
    my $trades = YAML::Syck::Load( $yml ) || die("Invalid yaml: $!");

    foreach my $trade_data (@$trades) {
        if ($trade_data->{direction} eq 'short') {
            #FXCM returns short positions as positive numbers,
            #convert to negative
            $trade_data->{size} *= -1;
        }
        my $trade = Finance::HostedTrader::Trade->new(
            $trade_data
        );

        if (!exists($self->{_positions}->{$trade->symbol})) {
            $self->{_positions}->{$trade->symbol} = Finance::HostedTrader::Position->new(symbol => $trade->symbol);
        }
        $self->{_positions}->{$trade->symbol}->addTrade($trade);
    }
}

=item C<getAsk($symbol)>

Returns the current ask(long) price for $symbol

=cut

sub getAsk {
    my ($self, $symbol) = @_;

    $symbol = $self->_convertSymbolToFXCM($symbol);
    return $self->_sendCmd("ask $symbol");
}

=item C<getBid($symbol)>

Returns the current bid(short) price for $symbol

=cut

sub getBid {
    my ($self, $symbol) = @_;

    $symbol = $self->_convertSymbolToFXCM($symbol);
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

    $symbol = $self->_convertSymbolToFXCM($symbol);
    my $data = $self->_sendCmd("openmarket $symbol $direction $amount");
    my ($orderID, $rate) = split(/ /, $data); #TODO don't need to return rate here
    
    return $self->getPosition($symbol)->getTrade($orderID);
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

=item C<getBaseUnit($symbol)>

Returns the base unit at which the symbol trades.

In FXCM, most symbols trade at multiples of 10.000, but some will vary ( XAGUSD uses multiples of 50 ).
=cut

sub getBaseUnit {
    my ($self, $symbol) = @_;

    $symbol = $self->_convertSymbolToFXCM($symbol);
    return $self->_sendCmd("baseunit $symbol");
}

=item C<getNav()>

Return the current net asset value in the account

=cut

sub getNav {
    my ($self) = @_;

    return $self->_sendCmd("nav");
}

=item C<getBaseCurrency>

=cut
sub getBaseCurrency {
    my ($self) = @_;
    return 'GBP'; #TODO

}

sub _convertSymbolToFXCM {
    my ($self, $symbol) = @_;

    die("Unsupported symbol '$symbol'") if (!exists($symbolMap{$symbol}));
    return $symbolMap{$symbol};
}


sub _sendCmd {
    my ($self, $cmd) = @_;
    my $sock = IO::Socket::INET->new(
                    PeerAddr => $self->{address},
                    PeerPort => $self->{port},
                    Proto    => 'tcp',
                    Timeout  => CONNECT_TIMEOUT,
                    ) or die($!);
   $sock->autoflush(1);


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

    close($sock);
}

sub getServerEpoch {
    my $self = shift;

    return time();
}

sub getServerDateTime {
    my $self = shift;

    my @v = gmtime();

    return sprintf('%d-%02d-%02d %02d:%02d:%02d', $v[5]+1900,$v[4]+1,$v[3],$v[2],$v[1],$v[0]);
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
