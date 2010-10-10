package Systems;

use strict;
use warnings;

use FXCMServer;
use Finance::HostedTrader::ExpressionParser;
use Finance::HostedTrader::Config;


use Moose;
use Config::Any;
use YAML::Tiny;

has 'name' => (
    is     => 'ro',
    isa    => 'Str',
    required=>1,
);

sub BUILD {
    my $self = shift;

    $self-> _loadSystem();
    $self->{_signal_processor} = Finance::HostedTrader::ExpressionParser->new();
    $self->{_system}->{symbols} = $self->_loadSymbols();
}

sub data {
    my $self = shift;
    return $self->{_system};
}

sub updateSymbols {
    my $self = shift;

    sub _getCurrentTrades {
#Call FXCMServer from limited scope
#so that we release the TCP connection
#to the single threaded server
#as soon as possible
# TODO this code should be agnostic to FXCMServer, instead should be using Finance::HostedTrader::Account
    my $s = FXCMServer->new();
        return $s->getTrades();
    }

    my $newSymbols = $self->getSymbolsSignalFilter($self->{_system}->{filter});
    my $trades = _getCurrentTrades();
    my $symbols = $self->_loadSymbols();#$self->{_system}->{symbols};
    #List of symbols for which there are open short positions
    my @symbols_to_keep_short = map {$_->{symbol}} grep {$_->{direction} eq 'short'} @{$trades}; 
    #List of symbols for which there are open long positions
    my @symbols_to_keep_long = map {$_->{symbol}} grep {$_->{direction} eq 'long'} @{$trades};

    #Add symbols for which there are existing positions to the list
    #If these are not kept in the trade list, open positions in these symbols will 
    #not be closed by the system
    $symbols->{short} = \@symbols_to_keep_short;
    $symbols->{long} = \@symbols_to_keep_long;
    use Data::Dumper;
    #Now add to the trade list symbols triggered by the system as trade opportunities
    foreach my $tradeDirection (qw /long short/ ) {
    foreach my $symbol ( @{$newSymbols->{$tradeDirection}} ) {
        #Don't add a symbol if it already exists in the list (avoid duplicates)
        next if (grep {/$symbol/} @{ $symbols->{$tradeDirection} });
        push @{ $symbols->{$tradeDirection} }, $symbol;
    }
    }

    my $yml = YAML::Tiny->new;
    $yml->[0] = { name => $self->name, symbols => $symbols};
    my $file = $self->_getSymbolFileName();
    $yml->write($file) || die("Failed to write symbols file $file. $!");
    $self->{_system}->{symbols} = $symbols;
}

#Return list of symbols to add to the system
sub getSymbolsSignalFilter {
    my $self = shift;
    my $filter = shift;

#Return list of all available symbols
    sub getAllSymbols {
    my $cfg         = Finance::HostedTrader::Config->new();

    return $cfg->symbols->all;
    }

    my $symbols = getAllSymbols();
    my $processor = $self->{_signal_processor};

    my $rv = { long => [], short => [] };

    foreach my $symbol (@$symbols) {
        if ($processor->checkSignal( {
            'expr' => $filter->{longSignal},
            'symbol' => $symbol,
            'tf' => $filter->{args}->{tf},
            'maxLoadedItems' => $filter->{args}->{maxLoadedItems},
            'period' => $filter->{args}->{period},
            'debug' => $filter->{args}->{debug},
        })) {
            push @{ $rv->{long} }, $symbol;
        } elsif ($processor->checkSignal( {
            'expr' => $filter->{shortSignal},
            'symbol' => $symbol,
            'tf' => $filter->{args}->{tf},
            'maxLoadedItems' => $filter->{args}->{maxLoadedItems},
            'period' => $filter->{args}->{period},
            'debug' => $filter->{args}->{debug},
        })) {
            push @{ $rv->{short} }, $symbol;
        }
    }

    return $rv if (!defined($filter->{topFilterIndicator}));
    return filterTopX($filter,$rv, $filter->{tradeSymbolLimit});
}

sub filterTopX {
    my $filter = shift;
    my $existing = shift;
    my $number_to_keep = shift;
    my @results;
    my $processor   = Finance::HostedTrader::ExpressionParser->new();

    my $calculateIndicator = sub {
        my $direction = shift;
        foreach my $symbol (@{ $existing->{$direction} }) {
            my $data = $processor->getIndicatorData( {
                'fields'        => "datetime,".$filter->{topFilterIndicator},
                'symbol'        => $symbol,
                'tf'            => $filter->{args}->{tf},
                'maxLoadedItems'=> $filter->{args}->{maxLoadedItems},
                'numItems'      => 1,
                'debug'         => $filter->{args}->{debug},
            } );
            $data = $data->[0];
            push @results, [ $symbol, $direction, $data->[1] ];
        }
    };

    &$calculateIndicator('long');
    &$calculateIndicator('short');

    my @sorted = sort { $b->[2] <=> $a->[2] } @results ;
    splice @sorted, $number_to_keep if ($number_to_keep < scalar(@sorted));

    my $rv = { long => [], short => [] };
    foreach my $item (@sorted) {
        push @{ $rv->{long} }, $item->[0] if ($item->[1] eq 'long');
        push @{ $rv->{short} }, $item->[0] if ($item->[1] eq 'short');
    }
    return $rv;
}

sub _getSymbolFileName {
    my ($self) = @_;

    return 'systems/'.$self->name.'.symbols.yml';
}

sub _loadSymbols {
    my $self = shift;
    my $file = $self->_getSymbolFileName;

    my $yaml = YAML::Tiny->new;
    $yaml = YAML::Tiny->read( $file ) || die("Cannot read symbols from $file. $!");

    die("invalid name in symbol file $file") if ($self->name ne $yaml->[0]->{name});

    return $yaml->[0]->{symbols};
}

sub checkEntrySignal {
    my $self = shift;

    return $self->_checkSignalWithAction('enter', @_);
}

sub checkExitSignal {
    my $self = shift;

    return $self->_checkSignalWithAction('exit', @_);
}

sub _checkSignalWithAction {
    my ($self, $action, $symbol, $tradeDirection) = @_;

    my $signal_definition = $self->{_system}->{signals}->{$action}->{$tradeDirection};

    return $self->{_signal_processor}->checkSignal(
        {
            'expr' => $signal_definition->{signal}, 
            'symbol' => $symbol,
            'tf' => $signal_definition->{timeframe},
            'maxLoadedItems' => $signal_definition->{maxLoadedItems},
            'period' => '1hour',
        }
    );
}

sub _loadSystem {
    my $self = shift;

    my $file = "systems/".$self->name.".yml";
    my $system = Config::Any->load_files(
        {
            files => [$file],
            use_ext => 1,
            flatten_to_hash => 1,
        }
    );

    die("failed to load system from $file. $!") unless defined($system);
    die("invalid name in symbol file $file") if ($self->name ne $system->{$file}->{name});
    $self->{_system} = $system->{$file};
}

sub getTradeSize {
my $self = shift;
my $account = shift;
my $symbol = shift;
my $direction = shift;

my $value;
my $maxLossPts;
my $system = $self->{_system};

    my $signal = $system->{signals}->{enter}->{$direction};
    my $maxLoss   = $account->getBalance * $system->{maxExposure} / 100;
    my $stopLoss = $self->{_signal_processor}->getIndicatorData( {
                symbol  => $symbol,
                tf      => $signal->{timeframe},
                fields  => 'datetime, ' . $signal->{initialStop},
                maxLoadedItems => $signal->{maxLoadedItems},
                numItems => 1,
                debug => 0,
    } );
    $stopLoss = $stopLoss->[0]->[1];
    my $base = uc(substr($symbol, -3));
    if ($base ne "GBP") {
        $maxLoss *= $account->getAsk("GBP$base");
    }

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
    my $baseUnit = $account->baseUnit($symbol); #This is the minimum amount that can be trader for the symbol
    my $amount = ($maxLoss / $maxLossPts) / $baseUnit;
    $amount = int($amount) * $baseUnit;
    return ($amount, $value, $stopLoss);
}

sub symbols {
    my ($self, $direction) = @_;

    return $self->{_system}->{symbols}->{$direction};
}


__PACKAGE__->meta->make_immutable;
1;
