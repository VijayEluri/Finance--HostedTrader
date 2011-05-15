package Finance::HostedTrader::Factory::Notifier;
=head1 NAME

    Finance::HostedTrader::Factory::Notifier - Interface to the Factory broker

=head1 SYNOPSIS

    use Finance::HostedTrader::Factory::Notifier;

    my $account = Finance::HostedTrader::Factory::Notifier->new(
                        SUBCLASS    => 'Production',
                  )->create_instance();

    my $test = Finance::HostedTrader::Factory::Notifier->new(
                        SUBCLASS    => 'UnitTest',
                  )->create_instance();

=head1 DESCRIPTION


=cut

use Moose;

use Moose::Util::TypeConstraints;

=head2 Properties

=over 12

=item C<SUBCLASS>

Readonly. Required.

The type of account to instantiate.

Supported values are:
    - Production
    - UnitTest

=cut
has [qw(SUBCLASS)] => ( is => 'ro', required => 1);

=back

=head2 Constructor

=item C<BUILD>

The constructor takes all arguments passed onto Factory::Notifier
and passes them to the target class defined by SUBCLASS.

=cut
sub BUILD {
    my $self = shift;
    my $args = shift;

    delete $args->{SUBCLASS};
    $self->{_args} = $args;
}
=back

=head2 Methods

=over 12

=cut

=item C<create_instance()>

Return an account instance of type SUBCLASS

=cut

sub create_instance {
my $self = shift;

    my $sc = $self->SUBCLASS();

    if ($sc eq 'Production') {
        require Finance::HostedTrader::Trader::Notifier::Production;
        return Finance::HostedTrader::Trader::Notifier::Production->new( $self->{_args} );
    } elsif ($sc eq 'UnitTest') {
        require Finance::HostedTrader::Trader::Notifier::UnitTest;
        return Finance::HostedTrader::Trader::Notifier::UnitTest->new( $self->{_args} );
    } else {
        die("Don't know about Notifier class: $sc");
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

L<Finance::HostedTrader::Notifier>,
L<Finance::HostedTrader::Notifier::Production>
L<Finance::HostedTrader::Notifier::UnitTest>

=cut
