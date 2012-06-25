package Finance::HostedTrader::Account::FXCM::ForexConnect;

# ABSTRACT: Finance::HostedTrader::Account::FXCM::ForexConnect - Interface to the FXCM broker

=head1 SYNOPSIS

    my $account = Finance::HostedTrader::Factory::Account->new(
                SUBCLASS => 'ForexConnect',
                username => '',
                password => '',
                accountType => 'demo', #real
            )->create_instance();

    print $account->getAsk('EURUSD');
    print $account->getBid('EURUSD');

    my ($openOrderID, $price) = $account->openMarket('EURUSD', 'long', 100000);
    my $trades = $account->getTrades();

    my $tradeID = $trades->[0]->{ID};
    my $closeOrderID = $account->closeMarket($tradeID, 100000);

=cut

use Moose;
extends 'Finance::HostedTrader::Account';

use Moose::Util::TypeConstraints;
use YAML::Syck;
use Finance::HostedTrader::Trade;

=attr C<username>

Account username

=cut
has username => (
    is      => 'ro',
    isa     => 'Str',
    required=> 1,
);

=attr C<password>

Account password

=cut
has password => (
    is      => 'ro',
    isa     => 'Str',
    required=> 1,
);

=attr C<accountType>


=cut
enum 'FXCMOrder2GOAccountType' => qw(Demo Real);
has accountType => (
    is     => 'ro',
    isa    => 'FXCMOrder2GOAccountType',
    required=>1,
);

=attr <notifier>
=cut
has notifier => (
    is     => 'ro',
    isa    => 'Maybe[Finance::HostedTrader::Trader::Notifier]',
    required=>1,
    default=> sub {
                    my $self = shift;
                    require Finance::HostedTrader::Trader::Notifier::Production;
                    return Finance::HostedTrader::Trader::Notifier::Production->new();
                  },
);


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

has '_fx' => (
    is      => 'ro',
    isa     => 'Finance::FXCM::Simple',
    lazy    => 1,
    builder => '_build_fx',
);

sub _build_fx {
    my $self = shift;

    require Finance::FXCM::Simple;
    return Finance::FXCM::Simple->new($self->username, $self->password, $self->accountType, 'http://www.fxcorporate.com/Hosts.jsp');
}

=method C<refreshPositions()>


=cut
sub refreshPositions {
    my ($self) = @_;

    $self->{_positions} = {};
    my $yml = $self->_fx->getTrades();

    return if (!$yml);
    my $trades = YAML::Syck::Load( $yml );
    die("Invalid yaml: $!") if (!$trades);

    foreach my $trade_data (@$trades) {
        $trade_data->{symbol} =~ s|/||;
        if ($trade_data->{direction} eq 'short') {
            #FXCM returns short positions as positive numbers,
            #convert to negative
            $trade_data->{size} *= -1;
        }
        my $trade = Finance::HostedTrader::Trade->new(
            $trade_data
        );
        my $trade_symbol = $trade->symbol;

        if (!exists($self->{_positions}->{$trade_symbol})) {
            $self->{_positions}->{$trade->symbol} = Finance::HostedTrader::Position->new(symbol => $trade_symbol);
        }
        $self->{_positions}->{$trade->symbol}->addTrade($trade);
    }
}

=method C<getAsk($symbol)>

Returns the current ask(long) price for $symbol

=cut

sub getAsk {
    my ($self, $symbol) = @_;

    $symbol = $self->_convertSymbolToFXCM($symbol);
    return $self->_fx->getAsk($symbol);
}

=method C<getBid($symbol)>

Returns the current bid(short) price for $symbol

=cut

sub getBid {
    my ($self, $symbol) = @_;

    $symbol = $self->_convertSymbolToFXCM($symbol);
    return $self->_fx->getBid($symbol);
}

=method C<openMarket($symbol, $direction, $amount>

Opens a trade in $symbol at current market price.

$direction can be either 'long' or 'short'

In FXCM, $amount needs to be a multiple of 10.000

Returns a list containing two elements:

$tradeID - This can be passed to closeMarket. It can also be retrieved via getTrades
$price   - The price at which the trade was executed.

=cut

augment 'openMarket' => sub {
    my ($self, $symbol, $direction, $amount, $stopLoss) = @_;

    my $fxcm_symbol = $self->_convertSymbolToFXCM($symbol);
    my $fxcm_direction = ($direction eq 'long' ? 'B' : 'S');
    my $isSuccess;

    #the openmarket call can fail if price moves
    #to quickly, so try it 3 times until it succeeds
    # TODO: not sure if this is still true, also, trying 3 times is tricky, because if the order was actually opened and what failed was checking that the open is successfull, we end up with multiple orders opened when we only wanted one. 
    TRY_OPENTRADE: foreach my $try (1..3) {
        eval {
            $self->_fx->openMarket($fxcm_symbol,$fxcm_direction,$amount);
            $isSuccess = 1;
            1;
        } or do {
            #TODO would be preferable to log something here
            next;
        };
        last TRY_OPENTRADE;
    }
    die("Failed to open order ($symbol, $direction,$amount,$stopLoss)") if(!$isSuccess);
};

=method C<closeMarket($tradeID, $amount)>

Closes a trade at current market price.

$tradeID is returned when calling openMarket(). It can also be retrieved via getTrades().

Returns $closedTradeID

=cut

augment closeMarket => sub {
    my ($self, $tradeID, $amount) = @_;

    return $self->_fx->closeMarket($tradeID,$amount);
};

=method C<getBaseUnit($symbol)>

Returns the base unit at which the symbol trades.

In FXCM, most symbols trade at multiples of 10.000, but some will vary ( XAGUSD uses multiples of 50 ).
=cut

sub getBaseUnit {
    my ($self, $symbol) = @_;

    $symbol = $self->_convertSymbolToFXCM($symbol);
    return $self->_fx->getBaseUnitSize($symbol);
}

=method C<balance()>

Return the current balance in the account (before profit/loss of existing positions)

=cut

sub balance {
    my ($self) = @_;

    return $self->_fx->getBalance();
}

=method C<getBaseCurrency>

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

    die($cmd . ' not implemented');
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

=method C<waitForNextTrade($system)>

Sleeps for 20 seconds. $system is ignored.

This method is called by Trader.pl.

=cut
sub waitForNextTrade {
    my ($self, $system) = @_;
    
    sleep(20);
}

1;
