package Finance::HostedTrader::Config::DB;
=head1 NAME

    Finance::HostedTrader::Config::DB - DB Configuration for the Finance::HostedTrader platform

=head1 SYNOPSIS

    use Finance::HostedTrader::Config::DB;
    my $obj = Finance::HostedTrader::Config::DB->new(
                    'dbhost'   => server_name,
                    'dbname'   => dbname,
                    'dbuser'   => dbuser,
                    'dbpasswd' => dbpasswd
                );

=head1 DESCRIPTION


=head2 METHODS

=over 12

=cut

use strict;
use warnings;
use Moose;

=item C<dbhost>

MySQL database server to connect to

=cut
has dbhost => (
    is     => 'ro',
    isa    => 'Str',
    required=>1,
);


=item C<dbname>

database name where data is stored

=cut
has dbname => (
    is     => 'ro',
    isa    => 'Str',
    required=>1,
);


=item C<dbuser>

database user name used to connect

=cut
has dbuser => (
    is     => 'ro',
    isa    => 'Str',
    required=>1,
);


=item C<dbpasswd>

database password used to connect

=cut
has dbpasswd => (
    is     => 'ro',
    isa    => 'Maybe[Str]',
    required=>0,
);

__PACKAGE__->meta->make_immutable;
1;

=back


=head1 LICENSE

This is released under the MIT license. See L<http://www.opensource.org/licenses/mit-license.php>.

=head1 AUTHOR

Joao Costa - L<http://zonalivre.org/>

=head1 SEE ALSO

L<Finance::HostedTrader::Config>

=cut
