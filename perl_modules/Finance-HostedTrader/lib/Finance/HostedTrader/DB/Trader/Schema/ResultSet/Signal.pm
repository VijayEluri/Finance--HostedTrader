package Finance::HostedTrader::DB::Trader::Schema::ResultSet::Signal;
use base 'DBIx::Class::ResultSet';

sub alerts {
    my $self = shift;
    return $self->search(
        {
        },
        {
            columns => [qw/ timeframe definition period direction /],
            join    => [qw/ signals_alerts /],
            prefetch=> [qw/ signals_alerts /],
        }
    );
}
1;
