package Systems;

use strict;
use warnings;

use FXCMServer;
use Finance::HostedTrader::ExpressionParser;
use Finance::HostedTrader::Config;


use Moose;
use Config::Any;
use YAML::Tiny;
use List::Compare::Functional qw( get_intersection );
use Hash::Merge;

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
    $self->{_symbolsLastUpdated} = 0;
}

sub data {
    my $self = shift;
    return $self->{_system};
}

sub symbolsLastUpdated {
    my $self = shift;

    return $self->{_symbolsLastUpdated};
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

    my $newSymbols = $self->getSymbolsSignalFilter($self->{_system}->{filters});
    my $trades = _getCurrentTrades();
    my $symbols = $self->_loadSymbols();#$self->{_system}->{symbols};
    #List of symbols for which there are open short positions
    my @symbols_to_keep_short = map {$_->{symbol}} grep {$_->{direction} eq 'short'} @{$trades}; 
    #List of symbols for which there are open long positions
    my @symbols_to_keep_long = map {$_->{symbol}} grep {$_->{direction} eq 'long'} @{$trades};

    #Add symbols for which there are existing positions to the list
    #If these are not kept in the trade list, open positions in these symbols will 
    #not be closed by the system
    #Only keep open trades if they were originally in this list already, otherwise the symbols were input by a different system instance
    $symbols->{short} = [ get_intersection('--unsorted', [ \@symbols_to_keep_short, $symbols->{short} ] ) ];
    $symbols->{long} = [ get_intersection('--unsorted', [ \@symbols_to_keep_long, $symbols->{long} ] ) ];

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
    $self->{_symbolsLastUpdated} = time();
}

#Return list of symbols to add to the system
sub getSymbolsSignalFilter {
    my $self = shift;
    my $filters = shift;

    my $long_symbols = $filters->{symbols}->{long};
    my $short_symbols = $filters->{symbols}->{short};
    my $processor = $self->{_signal_processor};

    my $rv = { long => [], short => [] };

    my $filter=$filters->{signals}->[0];

    foreach my $symbol (@$long_symbols) {
        if ($processor->checkSignal( {
            'expr' => $filter->{longSignal},
            'symbol' => $symbol,
            'tf' => $filter->{args}->{tf},
            'maxLoadedItems' => $filter->{args}->{maxLoadedItems},
            'period' => $filter->{args}->{period},
            'debug' => $filter->{args}->{debug},
        })) {
            push @{ $rv->{long} }, $symbol;
        }
    }

    foreach my $symbol (@$short_symbols) {
        if ($processor->checkSignal( {
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
    my $args = $self->{_system}->{signals}->{$action}->{args};

    return $self->{_signal_processor}->checkSignal(
        {
            'expr' => $signal_definition->{signal}, 
            'symbol' => $symbol,
            'tf' => $args->{timeframe},
            'maxLoadedItems' => $args->{maxLoadedItems},
            'period' => $args->{period},
        }
    );
}

sub _loadSystem {
    my $self = shift;

    my $file = "systems/".$self->name.".tradeable.yml";
    my $tradeable_filter = "systems/".$self->name.".yml";
    my @files = ($file, $tradeable_filter);
    my $system_all = Config::Any->load_files(
        {
            files => \@files,
            use_ext => 1,
            flatten_to_hash => 1,
        }
    );
    my $system = {};

	my $merge = Hash::Merge->new('custom_merge'); #The custom_merge behaviour is defined in Finance::HostedTrader::Config
    foreach my $file (@files) {
        next unless ( $system_all->{$file} );
        my $new_system = $merge->merge($system_all->{$file}, $system);
        $system=$new_system;
    }

    die("failed to load system from $file. $!") unless defined($system_all);
    die("invalid name in symbol file $file") if ($self->name ne $system->{name});
    $self->{_system} = $system;
}

sub getTradeSize {
my $self = shift;
my $account = shift;
my $symbol = shift;
my $direction = shift;

my $maxLossPts;
my $system = $self->{_system};

    my $args = $system->{signals}->{enter}->{args};
    my $signal = $system->{signals}->{enter}->{$direction};
    my $maxLoss   = $account->getNav() * $system->{maxExposure} / 100;
    my $stopLoss = $self->{_signal_processor}->getIndicatorData( {
                symbol  => $symbol,
                tf      => $args->{timeframe},
                fields  => 'datetime, ' . $system->{signals}->{exit}->{$direction}->{currentExitPoint},
                maxLoadedItems => $args->{maxLoadedItems},
                numItems => 1,
                debug => 0,
    } );
    $stopLoss = $stopLoss->[0]->[1];
    my $base = uc(substr($symbol, -3));
    if ($base ne "GBP") {
        $maxLoss *= $account->getAsk("GBP$base");
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
    my $baseUnit = $account->getBaseUnit($symbol); #This is the minimum amount that can be traded for the symbol
    my $amount = ($maxLoss / $maxLossPts) / $baseUnit;
    $amount = int($amount) * $baseUnit;
    die("trade size amount is negative: amount=$amount, baseUnit=$baseUnit, maxLoss=$maxLoss, maxLossPts=$maxLossPts") if ($amount < 0);
    return ($amount, $value, $stopLoss);
}

sub symbols {
    my ($self, $direction) = @_;

    return $self->{_system}->{symbols}->{$direction};
}


__PACKAGE__->meta->make_immutable;
1;
