package Finance::HostedTrader::Account;
# ABSTRACT: Finance::HostedTrader::Account - Account object

=head1 SYNOPSIS

    use Finance::HostedTrader::Account;
    my $obj = Finance::HostedTrader::Account->new(
                );

=cut


use strict;
use warnings;
use Moose;
use Finance::HostedTrader::ExpressionParser;
use Finance::HostedTrader::Position;

use Date::Manip;


##These should exist everywhere, regardless of broker

=head2 Properties

=over 12

=item C<startDate>

The time the trading system starts trading

=cut
has startDate => (
    is     => 'rw',
    isa    => 'Str',
    required=>1,
    default => 'now',
);

=item C<endDate>

The time the trading system stops trading

=cut
has endDate => (
    is     => 'rw',
    isa    => 'Str',
    required=>1,
    default => '-10 years ago',
);

=item C<notifier>
=cut
has 'notifier' => (
    is     => 'ro',
    isa    => 'Finance::HostedTrader::Trader::Notifier',
    required=>0,
);

has '_signal_processor' => (
    is      => 'ro',
    isa     => 'Finance::HostedTrader::ExpressionParser',
    lazy    => 1,
    builder => '_build_signal_processor',
);

sub _build_signal_processor {
    return Finance::HostedTrader::ExpressionParser->new();
}
=back

=head2 Constructor

=over 12

=item C<BUILD>

Constructor.

Converts {start,end}Date to 'YYYY-MM-DD hh:mm:ss' format.
Validates dates.
=cut
sub BUILD {
    my $self = shift;

    my $startDate = UnixDate($self->startDate, '%Y-%m-%d %H:%M:%S');
    die("Invalid date format: " . $self->startDate) if (!$startDate);
    my $endDate = UnixDate($self->endDate, '%Y-%m-%d %H:%M:%S');
    die("Invalid date format: " . $self->endDate) if (!$endDate);
    die("End date cannot be earlier than start date") if ( $endDate lt $startDate);
    $self->startDate($startDate);
    $self->endDate($endDate);
    $self->{_positions} = {};
}

=back

=method C<refreshPositions()>

This method must be overriden. It updates $self->{_positions} with an hash ref keyed by symbol with a L<Finance::HostedTrader::Position> object as value.

This method will typically have to read existing positions from the Account provider (eg: L<Finance::HostedTrader::Account::FXCM::ForexConnect>)
and store them in the Account object for local access.

It gets called by getPosition and getPositions


=cut
sub refreshPositions {
    die("overrideme");
}

=method C<getAsk($symbol)>

This method must be overriden. Returns the current ask price for $symbol.

=cut
sub getAsk {
    die("overrideme");
}

=method C<getBid>

This method must be overriden. Returns the current bid price for $symbol.

=cut
sub getBid {
    die("overrideme");
}

=method C<openMarket($symbol, $direction, $amount>

This method must be overriden. Opens a trade in $symbol at current market price.

$direction can be either 'long' or 'short'

Returns a list containing two elements:

$tradeID - This can be passed to closeMarket. It can also be retrieved via getTrades
$price   - The price at which the trade was executed.

If a notifier has been defined, the L<Finance::HostedTrader::Notifier> open method is called after the trade is open.

=cut
sub openMarket {
    my ($self, $symbol, $direction, $amount, $stopLoss) = @_;
    my $trade = inner();
    
    if (!$trade) {
        die("openMarket did not return a trade object\nParameters were: $symbol $direction $amount $stopLoss");
    }
    
    my $notifier = $self->notifier();
    if ($notifier) {
        $notifier->open(
            symbol      => $symbol,
            direction   => $direction,
            amount      => $amount, 
            stopLoss    => $stopLoss,
            orderID     => $trade->id,
            rate        => $trade->openPrice,
            now         => $self->getServerDateTime(),
            nav         => $self->getNav(),
            balance     => $self->balance(),
        );
    }
    
    return $trade;
}

=method C<closeMarket($tradeID, $amount)>

This method must be overriden. Closes a trade at current market price.

$tradeID is returned when calling openMarket(). It can also be retrieved via getTrades().

Returns $closedTradeID

=cut
sub closeMarket {
    die("overrideme");
}

=item C<getBaseUnit($symbol)>

This method must be overriden. Returns the base unit at which the symbol trades.

Eg, if baseUnit=10000, the symbol can only trade in multiples of 10000 (15000 would be an invalid trade size).

=cut
sub getBaseUnit {
    die("overrideme");
}

=item C<getNav()>

This method must be overriden. Return the current net asset value in the account.

=cut
sub getNav {
    die("overrideme");
}r

=item C<getBaseCurrency()>

This method must be overriden. Returns the currency in which funds are held in this account. Useful to calculate profit/loss.

=cut
sub getBaseCurrency {
    die("overrideme");
}r

=item C<getServerEpoch()>

This method must be overriden. Returns the current unix epoch time on the account server.

=cut
sub getServerEpoch {
    die("overrideme");
}

=item C<getServerDateTime()>

This method must be overriden. Returns the current date/time on the account server in '%Y-%m-%d %H:%M:%S' format.

=cut
sub getServerDateTime {
    die("overrideme");
}

=method C<checkSignal($symbol, $signal, $args)>

Returns true if the given $signal/$args occurs in $symbol

=cut
sub checkSignal {
    my ($self, $symbol, $signal_definition, $signal_args) = @_;

    return $self->_signal_processor->checkSignal(
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

=method C<getIndicatorValue($symbol, $indicator, $args)

Returns the indicator value of $indicator/$args on $symbol.

=cut
sub getIndicatorValue {
    my ($self, $symbol, $indicator, $args) = @_;

    my $value = $self->_signal_processor->getIndicatorData( {
                symbol  => $symbol,
                tf      => $args->{timeframe},
                fields  => 'datetime, ' . $indicator,
                maxLoadedItems => $args->{maxLoadedItems},
                numItems => 1,
                debug => $args->{debug},
    } );

    return $value->[0]->[1];
}

=method C<waitForNextTrade($system)>

=cut
sub waitForNextTrade {
    my ($self, $system) = @_;

    die('overrideme');
}

#=method C<convertToBaseCurrency($amount, $currentCurrency, $bidask>
#
#Converts $amount from $currentCurrency to the account's base currency, using either 'bid' or 'ask' price.
#
#=cut
#sub convertToBaseCurrency {
#    my ($self, $amount, $currentCurrency, $bidask) = @_;
#    $bidask = 'ask' if (!$bidask);
#
#    my $baseCurrency = $self->getBaseCurrency();
#
#    return $amount if ($baseCurrency eq $currentCurrency);
#    my $pair = $baseCurrency . $currentCurrency;
#    if ($bidask eq 'ask') {
#        return $amount / $self->getAsk($pair);
#    } elsif ($bidask eq 'bid') {
#        return $amount / $self->getBid($pair);
#    } else {
#        die("Invalid value in bidask argument: '$bidask'");
#    }
#}

=method C<convertBaseUnit($symbol, $amount)>

Convert $amount to the base unit supported by $symbol.

See the L</getBaseUnit($symbol)> method.

=cut
sub convertBaseUnit {
    my ($self, $symbol, $amount) = @_;
    my $baseUnit = $self->getBaseUnit($symbol);

    return int($amount / $baseUnit) * $baseUnit;
}

=method C<getPosition($symbol)>

Returns a L<Finance::HostedTrader::Position> object for $symbol.

This object will contain information about all open trades in $symbol.

=cut
sub getPosition {
    my ($self, $symbol) = @_;

    $self->refreshPositions();
    my $positions = $self->{_positions};
    return Finance::HostedTrader::Position->new(symbol=>$symbol) if (!defined($positions->{$symbol}));
    return $positions->{$symbol};
}

=method C<getPositions()>

Returns a hashref whose key is a "trading symbol" and value a L<Finance::HostedTrader::Position> object for that symbol.

=cut
sub getPositions {
    my ($self) = @_;

    $self->refreshPositions();
    return $self->{_positions};
}

=method C<closeTrades($symbol,$direction)>

Closes all trades in the given $symbol/$direction at market.

=cut
sub closeTrades {
    my ($self, $symbol, $directionToClose) = @_;

    my $posSize = 0;
    my $position = $self->getPosition($symbol);
    foreach my $trade (@{ $position->getOpenTradeList }) {
        my $trade_direction = $trade->direction;
        next if ($trade_direction ne $directionToClose);
        $self->closeMarket($trade->id, abs($trade->size));
        $posSize += $trade->size;
    }
    
    my $notifier = $self->notifier;
    if ($notifier) {
        my $value = ($directionToClose eq 'long' ? $self->getAsk($symbol) : $self->getBid($symbol) );
        $notifier->close(
            symbol      => $symbol,
            direction   => $directionToClose,
            amount      => $posSize, 
            currentValue=> $value,
            now         => $self->getServerDateTime(),
            nav         => $self->getNav(),
            balance     => $self->balance(),
        );
    }
}

=method C<pl()>

Profit/Loss for currently open positions

=cut
sub pl {
    my $self = shift;
    my $pl = 0;

    my $positions = $self->getPositions();
    foreach my $symbol (keys %{$positions}) {
        my $position = $positions->{$symbol};
        $pl += $position->pl;
    }

    return $pl;
}

=method C<balance()>

Current account balance, excluding profit/loss of open positions

=cut
sub balance {
    my $self = shift;

    return $self->getNav() - $self->pl();
}

my %symbolBaseMap = (
    AUDCAD => 'CAD',
    AUDCHF => 'CHF',
    AUDJPY => 'JPY',
    AUDNZD => 'NZD',
    AUDUSD => 'USD',
    AUS200 => 'AUD',
    CADCHF => 'CHF',
    CADJPY => 'JPY',
    CHFJPY => 'JPY',
    CHFNOK => 'NOK',
    CHFSEK => 'SEK',
    EURAUD => 'AUD',
    EURCAD => 'CAD',
    EURCHF => 'CHF',
    EURDKK => 'DKK',
    EURGBP => 'GBP',
    EURJPY => 'JPY',
    EURNOK => 'NOK',
    EURNZD => 'NZD',
    EURSEK => 'SEK',
    EURTRY => 'TRY',
    EURUSD => 'USD',
    GBPAUD => 'AUD',
    GBPCAD => 'CAD',
    GBPCHF => 'CHF',
    GBPJPY => 'JPY',
    GBPNZD => 'NZD',
    GBPSEK => 'SEK',
    GBPUSD => 'USD',
    HKDJPY => 'JPY',
    NOKJPY => 'JPY',
    NZDCAD => 'CAD',
    NZDCHF => 'CHF',
    NZDJPY => 'JPY',
    NZDUSD => 'USD',
    SEKJPY => 'JPY',
    SGDJPY => 'JPY',
    TRYJPY => 'JPY',
    USDCAD => 'CAD',
    USDCHF => 'CHF',
    USDDKK => 'DKK',
    USDHKD => 'HKD',
    USDJPY => 'JPY',
    USDMXN => 'MXN',
    USDNOK => 'NOK',
    USDSEK => 'SEK',
    USDSGD => 'SGD',
    USDTRY => 'TRY',
    USDZAR => 'ZAR',
    XAGUSD => 'USD',
    XAUUSD => 'USD',
    ZARJPY => 'JPY',
    ESP35  => 'EUR',
    FRA40  => 'EUR',
    GER30  => 'EUR',
    HKG33  => 'HKD',
    ITA40  => 'EUR',
    JPN225 => 'JPY',
    NAS100 => 'USD',
    SPX500 => 'USD',
    SUI30  => 'CHF',
    SWE30  => 'SEK',
    UK100  => 'GBP',
    UKOil  => 'GBP',
    US30   => 'USD',
    USOil  => 'USD',
);

=method C<getSymbolBase($symbol)>

Returns the base currency for a symbol, useful for calculating profit/loss.

Eg:
 US Stocks => 'USD'
 EURUSD => 'USD'
 USDCHF => 'CHF'

=cut
sub getSymbolBase {
    my ($self, $symbol) = @_;

    die("Unsupported symbol '$symbol'") if (!exists($symbolBaseMap{$symbol}));
    return $symbolBaseMap{$symbol};
}

__PACKAGE__->meta->make_immutable;
1;

=back


=head1 LICENSE

This is released under the MIT license. See L<http://www.opensource.org/licenses/mit-license.php>.

=head1 AUTHOR

Joao Costa - L<http://zonalivre.org/>

=head1 SEE ALSO

L<Finance::HostedTrader::Factory::Account>
L<Finance::HostedTrader::Position>

=cut
