package TestSystem;

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

    $yml->write("systems/$systemName.tradeable.yml") || die($!);
    if (-e "systems/$systemName.symbols.yml" ) { unlink("systems/$systemName.symbols.yml") || die($!); }
    system('perl '.$ENV.' ../data/fxcm/servers/Trader/Trader.pl '.$args.' --class=UnitTest --startDate="'.$self->startDate.'" --endDate="'.$self->endDate.'" --expectedTradesFile=' . $self->resultsFile);
}

1;
