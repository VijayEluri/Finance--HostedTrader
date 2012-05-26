package Finance::HostedTrader::Config::DB;
# ABSTRACT: Finance::HostedTrader::Config::DB - DB Configuration for the Finance::HostedTrader platform

=head1 SYNOPSIS

    use Finance::HostedTrader::Config::DB;
    my $obj = Finance::HostedTrader::Config::DB->new(
                    'dbhost'   => server_name,
                    'dbname'   => dbname,
                    'dbuser'   => dbuser,
                    'dbpasswd' => dbpasswd
                );

=cut

use strict;
use warnings;
use Moose;

=attr C<dbhost>

MySQL database server to connect to

=cut
has dbhost => (
    is     => 'ro',
    isa    => 'Str',
    required=>1,
);


=attr C<dbname>

database name where data is stored

=cut
has dbname => (
    is     => 'ro',
    isa    => 'Str',
    required=>1,
);


=attr C<dbuser>

database user name used to connect

=cut
has dbuser => (
    is     => 'ro',
    isa    => 'Str',
    required=>1,
);


=attr C<dbpasswd>

database password used to connect

=cut
has dbpasswd => (
    is     => 'ro',
    isa    => 'Maybe[Str]',
    required=>0,
);

__PACKAGE__->meta->make_immutable;
1;



=head1 SEE ALSO

L<Finance::HostedTrader::Config>

=cut
