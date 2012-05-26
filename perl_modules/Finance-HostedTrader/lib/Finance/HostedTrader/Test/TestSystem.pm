package Finance::HostedTrader::Test::TestSystem;

# ABSTRACT: Finance::HostedTrader::Test::TestSystem - Utilities for running system as a unit test

use Moose;

=attr C<symbols>
=cut
has symbols => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
);

=attr C<systenName>
=cut
has systemName => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=attr C<startDate>
=cut
has startDate => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=attr C<endDate>
=cut
has endDate => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=attr C<resultsFile>
=cut
has resultsFile => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=attr C<pathToSystems>
=cut
has pathToSystems => (
    is      => 'rw',
    isa     => 'Str',
    default => 'systems',
    required=> 1,
);

=method C<run>
=cut
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

=head1 SEE ALSO
L<Trader.pl>
=cut
1;
