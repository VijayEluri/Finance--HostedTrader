package Finance::HostedTrader::Factory::Account;
=head1 NAME

    Finance::HostedTrader::Factory::Account - Interface to the Factory broker

=head1 SYNOPSIS

    use Finance::HostedTrader::Factory::Account;
    my $account = Finance::HostedTrader::Factory::Account->new( SUBCLASS => 'FXCM', address => $address, port => $port)->create_instance();

=head1 DESCRIPTION


=head2 Properties

=over 12

=cut

use Moose;

use Moose::Util::TypeConstraints;


has [qw(SUBCLASS)] => ( is => 'ro', required => 1);
has [qw(address port)] => ( is => 'ro', required => 0);


=back

=head2 Methods

=over 12

=cut

=item C<create_instance>

=cut

sub create_instance {
my $self = shift;

    my $sc = $self->SUBCLASS();

    if ($sc eq 'FXCM') {
        require Finance::HostedTrader::Account::FXCM;
        return Finance::HostedTrader::Account::FXCM->new( address => $self->address, port => $self->port );
    } elsif ($sc eq 'UnitTest') {
        require Finance::HostedTrader::Account::UnitTest;
        return Finance::HostedTrader::Account::UnitTest->new( );
    } else {
        die("Don't know about Account class: $sc");
    }
}


__PACKAGE__->meta->make_immutable;

1;

=back

=head1 LICENSE

This is released under the MIT license. See L<http://www.opensource.org/licenses/mit-license.php>.

=head1 AUTHOR

Joao Costa - L<http://zonalivre.org/>

=head1 SEE ALSO

L<Finance::HostedTrader::Account>,
L<Finance::HostedTrader::Account::FXCM>
L<Finance::HostedTrader::Account::UnitTest>

=cut
