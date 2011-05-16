package Finance::HostedTrader::Trader;

use strict;
use warnings;

use Finance::HostedTrader::Config;
use Finance::HostedTrader::Position;
use Finance::HostedTrader::System;


use Moose;
use List::Compare::Functional qw( get_intersection );

has 'system' => (
    is     => 'ro',
    isa    => 'Finance::HostedTrader::System',
    required=>1,
);

has 'account' => (
    is     => 'ro',
    isa    => 'Finance::HostedTrader::Account',
    required=>1,
);

sub updateSymbols {
    my $self = shift;
    my $account = $self->account;

    my %symbols = (
        'long' => {},
        'short' => {},
    );


# Trade symbols where there are open positions
    my $positions = $account->getPositions();
    foreach my $symbol (keys %{$positions}) {
        my $position = $positions->{$symbol};
        foreach my $trade (@{$position->getOpenTradeList}) {
            my $direction = $trade->direction;
            if ($direction eq 'long') {
                $symbols{long}->{$symbol} = 1;
            } elsif ($direction eq 'short') {
                $symbols{short}->{$symbol} = 1;
            } else {
                die('Invalid trade direction: ' . $trade->direction);
            }
        }
    }

# And also symbols which match the system filter
    my $newSymbols = $self->getSymbolsSignalFilter($self->system->{filters});
    foreach my $tradeDirection (qw /long short/ ) {
        foreach my $symbol ( @{$newSymbols->{$tradeDirection}} ) {
            $symbols{$tradeDirection}->{$symbol} = 1;
        }
    }

# Write the unique symbols to a yml file
    $symbols{long} = [ keys %{$symbols{long}} ];
    $symbols{short} = [ keys %{$symbols{short}} ];

    my $yml = YAML::Tiny->new;
    $yml->[0] = { name => $self->system->name, symbols => \%symbols};
    my $file = $self->system->_getSymbolFileName();
    $yml->write($file) || die("Failed to write symbols file $file. $!");
    $self->system->{symbols} = \%symbols;
    $self->system->{_symbolsLastUpdated} = $account->getServerEpoch();
}

#Return list of symbols to add to the system
sub getSymbolsSignalFilter {
    my $self = shift;
    my $filters = shift;

    my $long_symbols = $filters->{symbols}->{long};
    my $short_symbols = $filters->{symbols}->{short};
    my $account = $self->account;

    my $rv = { long => [], short => [] };

    my $filter=$filters->{signals}->[0];#TODO should loop through every filter signal available ?

    foreach my $symbol (@$long_symbols) {
        if ($account->checkSignal(
                $symbol,
                $filter->{longSignal},
                $filter->{args}
        )) {
            push @{ $rv->{long} }, $symbol;
        }
    }

    foreach my $symbol (@$short_symbols) {
        if ($account->checkSignal(
            $symbol,
            $filter->{shortSignal},
            $filter->{args},
        )) {
            push @{ $rv->{short} }, $symbol;
        }
    }

    return $rv;
}

sub getEntryValue {
    my $self = shift;

    return $self->_getSignalValue('enter', @_);
}

sub getExitValue {
    my $self = shift;

    return $self->_getSignalValue('exit', @_);
}

sub _getSignalValue {
    my ($self, $action, $symbol, $tradeDirection) = @_;

    my $signal = $self->system->{signals}->{$action};#TODO what if there are multiple signals ?

    return $self->account->getIndicatorValue(
                $symbol, 
                $signal->{$tradeDirection}->{currentPoint},
                $signal->{args}
    );
}

sub checkEntrySignal {
    my $self = shift;

    return $self->_checkSignalWithAction('enter', @_);
}

sub checkAddUpSignal {
    my $self = shift;

    return $self->_checkSignalWithAction('add', @_);
}

sub checkExitSignal {
    my $self = shift;

    return $self->_checkSignalWithAction('exit', @_);
}

sub _checkSignalWithAction {
    my ($self, $action, $symbol, $tradeDirection) = @_;

    my $signal = $self->system->{signals}->{$action};
    die("System definition file is missing entry signals->$action ") if (!defined($signal));
    my $signal_definition = $signal->{$tradeDirection};#TODO what if there are multiple signals ?
    my $signal_args = $signal->{args};

    return $self->account->checkSignal(
                    $symbol,
                    $signal_definition->{signal},
                    $signal_args
    );
}


=item C<amountAtRisk($position)

How much capital will be lost/gained if $ position closes at the stop loss
level defined by this system.

This returned value is relative to the opening price and does not take into
account current profit/loss.
=cut
sub amountAtRisk {
    my $self = shift;
    my $position = shift;
    my $account = $self->account;
    my $symbol = $position->symbol;

    my $size = $position->size();
    my $direction = ($size > 0 ? 'long' : 'short');
    my $stopLoss = $self->_getSignalValue('exit', $symbol, $direction);
    die("Could not get stop loss for $symbol $direction") if (!defined($stopLoss));
    my $openPrice = $position->averagePrice();
    return 0 if (!$openPrice);

    my $pl = ( $openPrice - $stopLoss ) * $size;

    my $base = uc(substr($symbol, -3));

    if ($base ne "GBP") { # TODO: should not be hardcoded that account is based on GBP
        $pl /= $account->getAsk("GBP$base");
    }
    
    return $pl; #TODO this is not working for net short positions
}

sub getTradeSize {
my $self = shift;
my $symbol = shift;
my $direction = shift;
my $position = shift;

$position = Finance::HostedTrader::Position->new(symbol => $symbol) if (!defined($position));

my $maxLossPts;
my $system = $self->system;
my $trades = $position->getOpenTradeList;
my $numTrades = scalar(@$trades);
my $account = $self->account;
my $action = ( $numTrades == 0 ? 'enter' : 'add');
my $allowedExposure = $self->system->{signals}->{$action}->{$direction}->{exposure};

    if ($action eq 'add') {
        if ($numTrades > scalar(@$allowedExposure)) {
            return (0,undef,undef);
        }
        $allowedExposure = $allowedExposure->[$numTrades-1];
    }
    $allowedExposure = $allowedExposure / 100;

    my $balance = $account->balance();
    die("balance is negative") if ($balance < 0);
    my $amountAtRisk = $self->amountAtRisk($position);
    my $existingExposure = $amountAtRisk / $balance;

    my $maxExposure = $allowedExposure - $existingExposure;
    return (0,undef,undef) if ($maxExposure <= 0);

    my $maxLossAmount   = $balance * $maxExposure;
    my $stopLoss = $self->_getSignalValue('exit', $symbol, $direction);
    my $base = $account->getSymbolBase($symbol);

    if ($base ne "GBP") { # TODO: should not be hardcoded that account is based on GBP
        $maxLossAmount *= $account->getAsk("GBP$base");
    }

    my $value;
    if ($direction eq "long") {
        $value = $account->getAsk($symbol);
        $maxLossPts = $value - $stopLoss;
    } else {
        $value = $account->getBid($symbol);
        $maxLossPts = $stopLoss - $value;
    }

    if ( $maxLossPts <= 0 ) {
        die("Tried to set stop to " . $stopLoss . " but current price is " . $value);
    }
    my $amount = $account->convertBaseUnit($symbol, $maxLossAmount / $maxLossPts);
    #print "SIZE: $amount\t$existingExposure\t$amountAtRisk\t$maxExposure\t$maxLossAmount\t".$account->{_now}."\n";
    die('Tried to open trade with negative amount. This shouldn not happen unless there is a bug') if ($amount < 0);
    return ($amount, $value, $stopLoss);
}

__PACKAGE__->meta->make_immutable;
1;
