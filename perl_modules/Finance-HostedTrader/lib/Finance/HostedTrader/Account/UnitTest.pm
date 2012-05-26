package Finance::HostedTrader::Account::UnitTest;

use Moose;
extends 'Finance::HostedTrader::Account';

use Moose::Util::TypeConstraints;
use Finance::HostedTrader::Trade;
use Finance::HostedTrader::Config;

use Date::Manip;
use Date::Calc qw (Add_Delta_DHMS Delta_DHMS Date_to_Time);
use Time::HiRes;



# ABSTRACT: Finance::HostedTrader::Account::UnitTest - Interface to the UnitTest broker

=head1 SYNOPSIS

    use UnitTest;
    my $s = Finance::HostedTrader::Account::UnitTest->new( address => '127.0.0.1', port => 1500 );
    print $s->getAsk('EURUSD');
    print $s->getBid('EURUSD');

    my ($openOrderID, $price) = $s->openMarket('EURUSD', 'long', 100000);
    my $closeOrderID = $s->closeMarket($openOrderID, 100000);

=attr C<interval>

Number of seconds (in simulated time) to sleep between trades

=cut
has interval => (
    is     => 'ro',
    isa    => 'Int',
    required=>1,
    default => 240,
);

=attr C<system>
An instance of the L<Finance::HostedTrader::System> object
being traded by this instance of the unit test account.
Used to optimize test runs.
=cut
has system => (
    is     => 'ro',
    isa    => 'Finance::HostedTrader::System',
    required=>1,
); 

=attr C<skipToDatesWithSignal>

If set to true, system testing calculations only happen for periods
during which there are open/close signals.

This is the default option, as it makes calculations faster.

If set to false, all dates are checked, which is slower but better
mimics what would happen in reality.

This option mainly exists to test accuracy of the date skipping code.

=cut
has skipToDatesWithSignal => (
    is     => 'ro',
    isa    => 'Bool',
    required=>1,
    default=>1,
);

=attr C<expectedTradesFile>

Optional. A file in YAML format representing the trades
the system is expected to open.

=cut
has expectedTradesFile => (
    is     => 'ro',
    isa    => 'Str',
    required=>0,
);

=attr C<notifier>
Optional. An instance L<Finance::HostedTrader::Notifier>.

Defaults to L<Finance::HostedTrader::Trader::Notifier::UnitTest>.
=cut
has notifier => (
    is     => 'ro',
    isa    => 'Finance::HostedTrader::Trader::Notifier',
    required=>1,
    default=> sub {
                    my $self = shift;
                    require Finance::HostedTrader::Trader::Notifier::UnitTest;
                    return Finance::HostedTrader::Trader::Notifier::UnitTest->new( expectedTradesFile => $self->expectedTradesFile );
                  },
);

=method C<BUILD>

Initializes internal structures
=cut
sub BUILD {
    my $self = shift;

    $self->{_now} = UnixDate($self->startDate, '%Y-%m-%d %H:%M:%S');
    $self->{_now_epoch} = UnixDate($self->{_now}, '%s');
    $self->{_signal_cache} = {};
    $self->{_price_cache} = {};
    
    $self->{_account_data} = {
        balance => 50000,
    };
}


=method C<refreshPositions()>

Positions are kept in memory.
This method should calculate profit/loss of existing trades to keep data consistent
however that slows down unit testing considerably.

Instead, this module only calculates profit/loss in L</getNav()> which is called much
less often than refreshPositions and is enough to make the unit tests pass.

The drawback is that the UnitTest Account module will only have updated PL when getNav is called.  This will break anything that calls Finance::HostedTrader::Trade::pl, like L<Finance::HostedTrader::Report>

=cut
sub refreshPositions {
# positions are kept in memory



}

sub _updatePL {
    my $self = shift;

    # Calculate current p/l for each open trade
    my $positions = $self->{_positions};
    foreach my $key (keys(%{$positions})) {
        foreach my $trade (@{ $positions->{$key}->getOpenTradeList }) {
            my $pl = $self->_calculatePL($trade, $trade->size);

            $trade->pl($pl);
        }
    }
}

sub _calculatePL {
    my $self = shift;
    my $trade = shift;
    my $sizeToClose = shift;
    
    my $trade_size = $trade->size;
    die("sizeToClose parameter cannot be larger than trade->size") if (abs($sizeToClose) > abs($trade_size));
    my $symbol = $trade->symbol;
    my $trade_direction = $trade->direction;
    my $rate = ($trade_direction eq "long" ? $self->getAsk($symbol) : $self->getBid($symbol));
    my $base = $self->getSymbolBase($symbol);
    my $openPrice = $trade->openPrice;
    
    my $pl = ($rate - $openPrice) * $sizeToClose;
    if ($base ne "GBP") { # TODO: should not be hardcoded that account is based on GBP
        $pl /= $self->getAsk("GBP$base"); # TODO: this won't work for all cases( eg, if base is EUR)
    }
    
    return $pl;
}

=method C<getAsk($symbol)>

Reads the close of $symbol in the 5min timeframe. For the UnitTest class, getBid and getAsk return the same value.
=cut
sub getAsk {
    my ($self, $symbol) = @_;

    return $self->getIndicatorValue($symbol, 'close', { timeframe => '5min', maxLoadedItems => 1 });
}

=method C<getBid($symbol)>

Reads the close of $symbol in the 5min timeframe. For the UnitTest class, getBid and getAsk return the same value.
=cut
sub getBid {
    my ($self, $symbol) = @_;

    return $self->getIndicatorValue($symbol, 'close', { timeframe => '5min', maxLoadedItems => 1 });
}

=method C<openMarket($symbol, $direction, $amount)

Creates a new position in $symbol if one does not exist yet.
Adds a new trade to the position in $symbol.
=cut
augment 'openMarket' => sub {
    my ($self, $symbol, $direction, $amount, $stopLoss) = @_;

    my $id = $symbol.'|'.$direction.'|'.$amount.'|'.$self->{_now};
    my $rate = ($direction eq "long" ? $self->getAsk($symbol) : $self->getBid($symbol));

    my $trade = Finance::HostedTrader::Trade->new(
            id          => $id,
            symbol      => $symbol,
            direction   => $direction,
            openDate    => $self->{_now},
            openPrice   => $rate,
            size        => ($direction eq 'long' ? $amount : $amount*(-1)),
    );

    my $position = $self->getPosition($symbol);
    $position->addTrade($trade);
    $self->{_positions}->{$symbol} = $position;

    return $trade;
};

=method C<closeMarket($tradeID, $amount)>

=cut
sub closeMarket {
    my ($self, $tradeID, $amountToClose) = @_;
    
    die('$amountToClose must be positive value') if ($amountToClose <= 0);

    my $positions = $self->getPositions();
    foreach my $key (keys %{$positions}) {
        my $position = $positions->{$key};
        my $trade = $position->getTrade($tradeID);
        next if (!defined($trade));
        my $trade_size = $trade->size;
        die("Current implementation of closeMarket can only close full positions") if (abs($amountToClose) != abs($trade_size));

        my $trade_direction = $trade->direction;
        my $pl = $self->_calculatePL($trade, ($trade_direction eq 'long' ?  $amountToClose : -1*$amountToClose));
        $self->{_account_data}->{balance} += $pl;
        $position->deleteTrade($trade->id);
        return;
    }
}

=method C<getBaseUnit($symbol)>

TODO. Set base unit for other symbols.
=cut
sub getBaseUnit {
    my ($self, $symbol) = @_;
    
    my %base_units = (
        'XAGUSD' => 50,
    );
    
    return $base_units{$symbol} if (exists($base_units{$symbol}));
    return 10000;
}

=method C<getNav()>

    Returns account balance + account profit/loss
=cut
sub getNav {
    my $self = shift;

    $self->_updatePL;
    return sprintf("%.4f", $self->balance() + $self->pl());
}

=method C<balance>

=cut
sub balance {
    my ($self) = @_;
    return sprintf("%.4f", $self->{_account_data}->{balance});
}

#sub checkSignal_slow {
#    my ($self, $symbol, $signal_definition, $signal_args) = @_;
#
#    return $self->_signal_processor->checkSignal(
#        {
#            'expr' => $signal_definition, 
#            'symbol' => $symbol,
#            'tf' => $signal_args->{timeframe},
#            'maxLoadedItems' => $signal_args->{maxLoadedItems},
#            'period' => $signal_args->{period},
#            'debug' => $signal_args->{debug},
#            'simulatedNowValue' => $self->{_now},
#        }
#    );
#}

=method C<checkSignal($symbol, $signal_definition, $signal_args)>a

=cut
sub checkSignal {
    my ($self, $symbol, $signal_definition, $signal_args) = @_;
    my $cache = $self->{_signal_cache};

    #Get all signals for this symbol/signal_definition in the relevant time period and cache them
    if (!$cache->{$symbol} || !$cache->{$symbol}->{$signal_definition}) {

        #calculating max_loaded_periods adds a lot of code  but is important for performance
        my $startDate = UnixDate(DateCalc($self->{_now}, '- '.$signal_args->{period}."seconds"), '%Y-%m-%d %H:%M:%S');
        my $date = $self->endDate;
        my @d1 = (  substr($date,0,4),
                    substr($date,5,2),
                    substr($date,8,2),
                    substr($date,11,2),
                    substr($date,14,2),
                    substr($date,17,2)
                );

        $date = $startDate;
        my @d2 = (  substr($date,0,4),
                    substr($date,5,2),
                    substr($date,8,2),
                    substr($date,11,2),
                    substr($date,14,2),
                    substr($date,17,2)
                );
        my @r = Delta_DHMS(@d2,@d1);
        my $seconds_between_dates = ($r[0]*86400 + $r[1]*3600 + $r[2]*60 + $r[3]);
        my $seconds_in_tf = Finance::HostedTrader::Config->new()->timeframes->getTimeframeID($signal_args->{timeframe});
        my $max_loaded_periods = int(($seconds_between_dates / $seconds_in_tf) + 0.5) + $signal_args->{maxLoadedItems};


        $cache->{$symbol}->{$signal_definition} = $self->_signal_processor->getSignalData( {
            'expr' => $signal_definition, 
            'symbol' => $symbol,
            'tf' => $signal_args->{timeframe},
            'startPeriod' => $startDate,
            'endPeriod' => $self->endDate,
            'maxLoadedItems' => $max_loaded_periods,
        });

    }

    my $signal_list = $cache->{$symbol}->{$signal_definition};
    return undef if (!$signal_list || scalar(@$signal_list) == 0);

    my $signal;
    my $signal_date = 0;
    my $secs_in_period = $signal_args->{period} || 3600;
    my $date=$self->{_now};
    my $signal_valid_from = sprintf('%d-%02d-%02d %02d:%02d:%02d', Add_Delta_DHMS(substr($date,0,4),substr($date,5,2),substr($date,8,2),substr($date,11,2),substr($date,14,2),substr($date,17,2),0,0,0,$secs_in_period*(-1)));

    while(1) {
        $signal = $signal_list->[0];
        last if (!defined($signal));
        $signal_date = $signal->[0];
        last if ( $signal_valid_from lt $signal_date && ( !defined($signal_list->[1]) || $signal_list->[1]->[0] gt $self->{_now} ));
        shift @{ $signal_list };
    }
    

    if ($signal_date gt $self->{_now} || $signal_date lt $signal_valid_from) {
        $signal = undef;
    }

#my $old_value = $self->checkSignal_slow($symbol, $signal_definition, $signal_args);
#use Data::Compare;
#    if (!Compare(\$signal, \$old_value)) {
#        print $self->{_now}, "\n";
#        print "$symbol $signal_definition\n";
#        print Dumper(\$signal_args);
#        print Dumper(\$signal);
#        print Dumper(\$old_value);
#        print Dumper(\$signal_list);
#        use Data::Dumper;exit;
#    }
    return $signal;
}

sub getIndicatorValue {
    my ($self, $symbol, $indicator, $args) = @_;

    my $value = $self->_signal_processor->getIndicatorData( {
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
    my $interval = $self->interval;
    my $date = $self->{_now};
    
    if (!$self->skipToDatesWithSignal) {
        $self->{_now} = sprintf('%d-%02d-%02d %02d:%02d:%02d', Add_Delta_DHMS(substr($date,0,4),substr($date,5,2),substr($date,8,2),substr($date,11,2),substr($date,14,2),substr($date,17,2),0,0,0,$interval));
        $self->{_now_epoch} += $interval;
        return;
    }
    my $nextSignalDate = $self->_getNextSignalDate();

#Adjust next signal date to take into account the signal check interval
    if ($nextSignalDate) {    
        my $periods = int(delta_dates($nextSignalDate, $date) / $interval);
        $nextSignalDate = delta_add($date, $periods*$interval);
    }

    my $normalWaitDate = delta_add($date, $interval);
    my $nowWillBe = ($nextSignalDate && $nextSignalDate gt $normalWaitDate ? $nextSignalDate : $normalWaitDate);
    
    $self->{_now} = $nowWillBe;
    $self->{_now_epoch} = date_to_epoch($self->{_now});
}

# Returns the date of the next future signal
sub _getNextSignalDate {
    my $self = shift;
    my $date = $self->{_now};

    my $nextSymbolUpdateDate = epoch_to_date($self->system->getSymbolsNextUpdate);

    my $signals = $self->{_signal_cache};
    my @next_signals = ($nextSymbolUpdateDate);
    foreach my $symbol (keys(%$signals)) {
        foreach my $signal (keys(%{$signals->{$symbol}})) {
            my $data = $signals->{$symbol}->{$signal};
            push @next_signals, $data->[0]->[0] if ($data->[0] && $data->[0]->[0] gt $date);
            push @next_signals, $data->[1]->[0] if ($data->[1] && $data->[1]->[0] gt $date);
        }
    }
    @next_signals = sort (@next_signals);

    return $next_signals[0];
}

sub getServerEpoch {
    my $self = shift;

    return $self->{_now_epoch};
}

sub getServerDateTime {
    my $self = shift;

    return $self->{_now};
}


=method C<delta_add($date, $delta)>
Add $delta seconds to $date and returns the new date
=cut
sub delta_add {
    my ($date, $delta) = @_;

    return sprintf( '%d-%02d-%02d %02d:%02d:%02d',
                            Add_Delta_DHMS( substr($date,0,4),
                                            substr($date,5,2),
                                            substr($date,8,2),
                                            substr($date,11,2),
                                            substr($date,14,2),
                                            substr($date,17,2),
                                            0,0,0,$delta
                                           )
                          );
    
}

=method C<delta_dates($date1,$date2)>
    Returns the number of seconds between $date1 and $date2
=cut
sub delta_dates {
my $date1 = shift;
my $date2 = shift;
my @d1 = (
                substr($date1,0,4),
                substr($date1,5,2),
                substr($date1,8,2),
                substr($date1,11,2),
                substr($date1,14,2),
                substr($date1,17,2)
	);

my @d2 = (  substr($date2,0,4),
                substr($date2,5,2),
                substr($date2,8,2),
                substr($date2,11,2),
                substr($date2,14,2),
                substr($date2,17,2)
	);


my @r = Delta_DHMS(@d2,@d1);

my $v = ($r[0]*86400 + $r[1]*3600 + $r[2]*60 + $r[3]);
return $v;
}

=method C<epoch_to_date()>
=cut
sub epoch_to_date {
    my $epoch = shift;

    my ($sec, $min, $hr, $day, $month, $year, $weekday) = gmtime($epoch);    
    return sprintf( '%04d-%02d-%02d %02d:%02d:%02d',
                            $year+1900,
                            $month+1,
                            $day,
                            $hr,
                            $min,
                            $sec
                  );
}

=method C<date_to_epoch()>
=cut
sub date_to_epoch {
    my $date = shift;

    my $r = Date_to_Time(
                    substr($date,0,4),
                    substr($date,5,2),
                    substr($date,8,2),
                    substr($date,11,2),
                    substr($date,14,2),
                    substr($date,17,2)
                  );
}



1;
