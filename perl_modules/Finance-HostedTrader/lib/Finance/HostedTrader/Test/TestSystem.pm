package Finance::HostedTrader::Test::TestSystem;

use Moose;

has symbols => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
);

has systemName => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has startDate => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has endDate => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has resultsFile => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has pathToSystems => (
    is      => 'rw',
    isa     => 'Str',
    default => 'systems',
    required=> 1,
);

sub run {
    my $self = shift;
    my $args = shift || '';
    my $ENV=$ENV{HARNESS_PERL_SWITCHES} || '';
    my $systemName	= $self->systemName;
    my $symbols     = $self->symbols;

    my $yml = YAML::Tiny->new;
    $yml->[0] = {
        name => $systemName,
        filters => {
            symbols => $symbols
        }
    };

    $yml->write($self->pathToSystems."/$systemName.tradeable.yml") || die($!);
    if (-e $self->pathToSystems."/$systemName.symbols.yml" ) { unlink($self->pathToSystems."/$systemName.symbols.yml") || die($!); }
    system('perl '.$ENV.' ' . $ENV{TRADER_HOME} . '/data/fxcm/servers/Trader/Trader.pl '.$args.' --class=UnitTest --startDate="'.$self->startDate.'" --endDate="'.$self->endDate.'" --expectedTradesFile=' . $self->resultsFile . ' --pathToSystems="'.$self->pathToSystems.'"');
}

1;
