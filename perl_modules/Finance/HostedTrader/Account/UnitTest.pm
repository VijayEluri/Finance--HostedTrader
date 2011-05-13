package Finance::HostedTrader::Account::UnitTest;

use Moose;
extends 'Finance::HostedTrader::Account';

use Moose::Util::TypeConstraints;
use Finance::HostedTrader::Trade;
use Finance::HostedTrader::Config;

use Date::Manip;
use Date::Calc qw (Add_Delta_DHMS Delta_DHMS Date_to_Time);
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

=item C<interval>

Number of seconds (in simulated time) to sleep between trades

=cut
has interval => (
    is     => 'ro',
    isa    => 'Int',
    required=>1,
    default => 240,
);

=item C<system>

System being traded by this instance of the unit test account.
This is needed to optimize test runs.
=cut
has system => (
    is     => 'ro',
    isa    => 'Finance::HostedTrader::System',
    required=>1,
); 

=item C<skipSignalDates>

If set to true, system testing calculations only happen for periods
during which there are open/close signals.

This is the default option, as it makes calculations faster.

If set to false, all dates are checked, which is slower but better
mimics what would happen in reality.

This option mainly exists to test accuracy of the date skipping code.

=cut
has skipSignalDates => (
    is     => 'ro',
    isa    => 'Bool',
    required=>1,
    default=>1,
);

=back

=head2 Constructor

=item C<BUILD>

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


=head2 Methods

=over 12

=item C<refreshPositions()>

Positions are kept in memory.
This method calculates profit/loss of existing trades to keep data consistent
=cut
sub refreshPositions {
    my $self = shift;
# positions are kept in memory
# Calculate current p/l for each open trade
    my $positions = $self->{_positions};
    foreach my $key (keys(%{$positions})) {
        foreach my $trade (@{ $positions->{$key}->getTradeList }) {
            my $pl = $self->_calculatePL($trade, $trade->size);

            $trade->pl($pl);
        }
    }

}

sub _calculatePL {
    my $self = shift;
    my $trade = shift;
    my $size = shift;
    
    die("size parameter cannot be larger than trade->size") if ($size > $trade->size);
    my $symbol = $trade->symbol;
    my $rate = ($trade->direction eq "long" ? $self->getAsk($symbol) : $self->getBid($symbol));
    my $base = $self->getSymbolBase($symbol);
    my $openPrice = $trade->openPrice;
    
    my $pl = ($rate - $openPrice) * $size;
    if ($base ne "GBP") { # TODO: should not be hardcoded that account is based on GBP
        $pl /= $self->getAsk("GBP$base"); # TODO: this won't work for all cases( eg, if base is EUR)
    }
    
    return $pl;
}

=item C<getAsk($symbol)>

Reads the close of $symbol in the 5min timeframe. For the UnitTest class, getBid and getAsk return the same value.
=cut
sub getAsk {
    my ($self, $symbol) = @_;

    return $self->getIndicatorValue($symbol, 'close', { timeframe => '5min', maxLoadedItems => 1 });
    sub loadCache {
        my ($self, $symbol, $date) = @_;

        my $initDate = sprintf( '%d-%02d-%02d %02d:%02d:%02d',
                                Add_Delta_DHMS( substr($date,0,4),
                                                substr($date,5,2),
                                                substr($date,8,2),
                                                substr($date,11,2),
                                                substr($date,14,2),
                                                substr($date,17,2),
                                                0,0,0,$self->interval*(-1)
                                               )
                                );
        $date = $self->endDate;
        my $endDate = sprintf( '%d-%02d-%02d %02d:%02d:%02d',
                                Add_Delta_DHMS( substr($date,0,4),
                                                substr($date,5,2),
                                                substr($date,8,2),
                                                substr($date,11,2),
                                                substr($date,14,2),
                                                substr($date,17,2),
                                                0,0,0,$self->interval
                                               )
                                );
        #print "Return data from $initDate to $endDate";
        return $self->{_signal_processor}->getIndicatorData( {
                    symbol  => $symbol,
                    tf      => '5min',
                    fields  => 'datetime, close',
                    maxLoadedItems => 1000,
                    numItems => 1000,
                    debug => 0,
                    startPeriod => $initDate,
                    endPeriod => $endDate,
                    reverse => 1,
        } );

    }


    my $cache = $self->{_price_cache};


    my $date = $self->getServerDateTime();
    my $requested_period = sprintf("%s-%s-%s %s:%02d:00",
                substr($date,0,4),
                substr($date,5,2),
                substr($date,8,2),
                substr($date,11,2),
                int(substr($date,14,2)/5)*5);
#    print "Search for $requested_period\n";
#    print Dumper(\$cache);use Data::Dumper;exit;
    
    my $loop_count = 0;
    my $loadFrom = $self->{_now};
    while (1) {
        $cache->{$symbol} = loadCache($self, $symbol, $loadFrom) if (!$cache->{$symbol} || scalar(@{ $cache->{$symbol} }) <= 1);
        $date = $cache->{$symbol};
        if ($loop_count) {
#            print Dumper(\$date);
#            print Dumper(\$requested_period);
            print "exit loop" and exit if ($loop_count > 2);
        }
        last if (!$date || scalar(@$date) <= 1);
        
        for (my $i = scalar(@$date)-1; $i >= 0; $i--) {
            my $lastDate = $date->[$i];
            if ($lastDate->[0] eq $requested_period) {
                splice @$date, ($i > 0 ? $i+1 : 2);
#                my $realValue = $self->getIndicatorValue($symbol, 'close', { timeframe => '5min', maxLoadedItems => 1 });
#                if ($lastDate->[1] ne $realValue) {
#                    print Dumper(\$date);
#                    print Dumper(\$requested_period);
#                    print "bad return of $lastDate->[1]($lastDate->[0]) instead of $realValue ";
#                    exit;
#                }
                return $lastDate->[1];
            } elsif ($lastDate->[0] gt $requested_period) {
                my $lastDate = $date->[$i-1];
                splice @$date, ($i > 0 ? $i+1 : 2);
#                my $realValue = $self->getIndicatorValue($symbol, 'close', { timeframe => '5min', maxLoadedItems => 1 });
#                if ($lastDate->[1] ne $realValue) {
#                    print Dumper(\$date);
#                    print Dumper(\$requested_period);
#                    print "bad return of $lastDate->[1]($lastDate->[0]) instead of $realValue ";
#                    exit;
#                }
                return $lastDate->[1];
            }
        }
        $loadFrom = $date->[0]->[0];
        $cache->{$symbol} = undef;
        $loop_count++;
        #print "Loop $loop_count\n";
    }

    die("Could not find date, sorry");
    return $self->getIndicatorValue($symbol, 'close', { timeframe => '5min', maxLoadedItems => 1 });

    die('could not find values') if (!$cache->{$symbol} || scalar(@{ $cache->{$symbol} }) == 0);

    my $values = $cache->{$symbol};
    my $value;
    print Dumper(\$values);use Data::Dumper;exit;
    while (1) {
        $value = $values->[@$values-1];
        last if (!defined($value));
        my $indicator_date = $value->[0];
        $value = $value->[1];
        #last if ( $signal_valid_from lt $indicator_date && ( !defined($signal_list->[1]) || $signal_list->[1]->[0] gt $self->{_now} ));
        #shift @{ $signal_list };
    }


    return $self->getIndicatorValue($symbol, 'close', { timeframe => '5min', maxLoadedItems => 1 });
}

=item C<getBid($symbol)>

Reads the close of $symbol in the 5min timeframe. For the UnitTest class, getBid and getAsk return the same value.
=cut
sub getBid {
    my ($self, $symbol) = @_;

    return $self->getIndicatorValue($symbol, 'close', { timeframe => '5min', maxLoadedItems => 1 });
}

=item C<openMarket($symbol, $direction, $amount)

Creates a new position in $symbol if one does not exist yet.
Adds a new trade to the position in $symbol.
=cut
sub openMarket {
    my ($self, $symbol, $direction, $amount) = @_;

    my $id = $$ . Time::HiRes::time();
    my $rate = ($direction eq "long" ? $self->getAsk($symbol) : $self->getBid($symbol));

    my $trade = Finance::HostedTrader::Trade->new(
            id          => $id,
            symbol      => $symbol,
            direction   => $direction,
            openDate    => $self->{_now},
            openPrice   => $rate,
            size        => $amount,
    );

    my $position = $self->getPosition($symbol);
    $position->addTrade($trade);
    $self->{_positions}->{$symbol} = $position;

    return ($id, $rate);
}

=item C<closeMarket($tradeID, $amount)>

=cut
sub closeMarket {
    my ($self, $tradeID, $amount) = @_;

    my $positions = $self->getPositions();
    foreach my $key (keys %{$positions}) {
        my $position = $positions->{$key};
        my $trade = $position->getTrade($tradeID);
        die("Tried to close $amount which is more than trade size " . $trade->size) if ($amount > $trade->size);

        my $pl = $self->_calculatePL($trade, $amount);
        $self->{_account_data}->{balance} += $pl;

        if ($trade->size == $amount) {
            $position->deleteTrade($trade->id);
        } else {
            $trade->size($trade->size-$amount);
        }
    }
}

=item C<getBaseUnit($symbol)>

TODO. Always returns base unit as 50.
=cut
sub getBaseUnit {
    my ($self, $symbol) = @_;
    
    my %base_units = (
        'XAGUSD' => 50,
    );
    
    return $base_units{$symbol} if (exists($base_units{$symbol}));
    return 10000;
}

=item C<getNav()>

    Returns account balance + account profit/loss
=cut
sub getNav {
    my $self = shift;

    return $self->balance() + $self->pl();
}

=item C<balance>

=cut
sub balance {
    my ($self) = @_;
    return $self->{_account_data}->{balance};
}

#sub checkSignal_slow {
#    my ($self, $symbol, $signal_definition, $signal_args) = @_;
#
#    return $self->{_signal_processor}->checkSignal(
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

=item C<checkSignal($symbol, $signal_definition, $signal_args)>a

=cut
sub checkSignal {
    my ($self, $symbol, $signal_definition, $signal_args) = @_;
    my $cache = $self->{_signal_cache};

#Get all signals for this symbol/signal_definition in the relevant time period and cache them
    if (!$cache->{$symbol} || !$cache->{$symbol}->{$signal_definition}) {

#calculating max_loaded_periods adds a lot of code  but is important for performance
        my $startDate = UnixDate(DateCalc($self->{_now}, '- '.$signal_args->{period}), '%Y-%m-%d %H:%M:%S');
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


        $cache->{$symbol}->{$signal_definition} = $self->{_signal_processor}->getSignalData( {
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
    my $period = $signal_args->{period} || '1hour';
    my $secs_in_period =  Delta_Format(ParseDateDelta($period), 0, "%st");
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
    my $interval = $self->interval;
    my $date = $self->{_now};
    
    if (!$self->skipSignalDates) {
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


=item C<delta_add($date, $delta)>
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

=item C<delta_dates($date1,$date2)>
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

=item C<epoch_to_date()>
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

=item C<date_to_epoch()>
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

=back

=head1 LICENSE

This is released under the MIT license. See L<http://www.opensource.org/licenses/mit-license.php>.

=head1 AUTHOR

Joao Costa - L<http://zonalivre.org/>

=head1 SEE ALSO

L<Server.exe>

=cut
