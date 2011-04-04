package Systems;

use strict;
use warnings;

use Finance::HostedTrader::Config;


use Moose;
use Config::Any;
use YAML::Tiny;
use List::Compare::Functional qw( get_intersection );
use Hash::Merge;
use Data::Dumper;

has 'name' => (
    is     => 'ro',
    isa    => 'Str',
    required=>1,
);

has 'account' => (
    is     => 'ro',
    isa    => 'Finance::HostedTrader::Account',
    required=>1,
);

sub BUILD {
    my $self = shift;

    $self-> _loadSystem();
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
    my $account = $self->account;

    my %symbols = (
        'long' => {},
        'short' => {},
    );


# Trade symbols where there are open positions
    my $positions = $account->getPositions();
    foreach my $symbol (keys %{$positions}) {
        my $position = $positions->{$symbol};
        foreach my $trade (@{$position->trades}) {
            next if ($trade->status ne 'open');
            if ($trade->direction eq 'long') {
                $symbols{long}->{$symbol} = 1;
            } elsif ($trade->direction eq 'short') {
                $symbols{short}->{$symbol} = 1;
            } else {
                die('Invalid trade direction: ' . $trade->direction);
            }
        }
    }

# And also symbols which match the system filter
    my $newSymbols = $self->getSymbolsSignalFilter($self->{_system}->{filters});
    foreach my $tradeDirection (qw /long short/ ) {
        foreach my $symbol ( @{$newSymbols->{$tradeDirection}} ) {
            $symbols{$tradeDirection}->{$symbol} = 1;
        }
    }

# Write the unique symbols to a yml file
    $symbols{long} = [ keys %{$symbols{long}} ];
    $symbols{short} = [ keys %{$symbols{short}} ];
    print Dumper(\%symbols);
    my $yml = YAML::Tiny->new;
    $yml->[0] = { name => $self->name, symbols => \%symbols};
    my $file = $self->_getSymbolFileName();
    $yml->write($file) || die("Failed to write symbols file $file. $!");
    $self->{_system}->{symbols} = \%symbols;
    $self->{_symbolsLastUpdated} = time();
}

#Return list of symbols to add to the system
sub getSymbolsSignalFilter {
    my $self = shift;
    my $filters = shift;

    my $long_symbols = $filters->{symbols}->{long};
    my $short_symbols = $filters->{symbols}->{short};
    my $account = $self->account;

    my $rv = { long => [], short => [] };

    my $filter=$filters->{signals}->[0];

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

    my $signal = $self->{_system}->{signals}->{$action};

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

sub checkExitSignal {
    my $self = shift;

    return $self->_checkSignalWithAction('exit', @_);
}

sub _checkSignalWithAction {
    my ($self, $action, $symbol, $tradeDirection) = @_;

    my $signal_definition = $self->{_system}->{signals}->{$action}->{$tradeDirection};
    my $signal_args = $self->{_system}->{signals}->{$action}->{args};

    return $self->account->checkSignal(
                    $symbol,
                    $signal_definition->{signal},
                    $signal_args
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

sub maxNumberTrades {
my ($self) = @_;

my $exposurePerPosition = $self->{_system}->{maxExposure};
die("no exposure coefficients in system definition") if (!$exposurePerPosition || !scalar(@{$exposurePerPosition}));
return scalar(@{$exposurePerPosition});
}

sub getTradeSize {
my $self = shift;
my $symbol = shift;
my $direction = shift;
my $position = shift;

my $maxLossPts;
my $system = $self->{_system};
my $trades = $position->trades;
my $account = $self->account;


    my $exposurePerPosition = $system->{maxExposure};
    die("no exposure coefficients in system definition") if (!$exposurePerPosition || !scalar(@{$exposurePerPosition}));
    return (0,undef,undef) if (scalar(@$trades) >= scalar(@{$exposurePerPosition}));

    my $maxExposure = $exposurePerPosition->[scalar(@{$trades})];
    die("max exposure is negative") if ($maxExposure <0);
    my $nav = $account->getNav();
    die("nav is negative") if ($nav < 0);

    my $maxLoss   = $nav * $maxExposure / 100;
    my $stopLoss = $self->_getSignalValue('exit', $symbol, $direction);
    my $base = uc(substr($symbol, -3));

    if ($base ne "GBP") { # TODO: should not be hardcoded that account is based on GBP
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
    my $amount = $account->convertBaseUnit($symbol, $maxLoss / $maxLossPts);
    $amount -= $position->size;
    $amount = 0 if ($amount < 0);
    return ($amount, $value, $stopLoss);
}

sub symbols {
    my ($self, $direction) = @_;

    return $self->{_system}->{symbols}->{$direction};
}


__PACKAGE__->meta->make_immutable;
1;
