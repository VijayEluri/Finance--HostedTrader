package Finance::HostedTrader::Trader::Notifier;
=head1 NAME

    Finance::HostedTrader::Notifier - Notifier object

=head1 SYNOPSIS

    use Finance::HostedTrader::Notifier;
    my $obj = Finance::HostedTrader::Notifier->new(
                );

=head1 DESCRIPTION


=cut


use strict;
use warnings;

use Moose;
use Params::Validate qw(:all);
use Scalar::Util;

=head2 Properties

=over 12

=back

=head2 Constructor

=over 12

=item C<BUILD>

Constructor.

=cut

=back


=head2 METHODS


=over 12


=item C<open()>

=cut

sub _isPositiveNum {
    my $value = shift;
    return Scalar::Util::looks_like_number($value) && $value > 0;    
}

sub _isDirection {
    my $value = shift;
    return $value eq 'long' || $value eq 'short';
}

around 'open' => sub {
    my $orig = shift;
    my $self = shift;

    validate( @_,
              {
                symbol      =>  { type => SCALAR },
                direction   =>  { type => SCALAR, callbacks => { v => \&_isDirection } },
                amount      =>  { type => SCALAR, regex => qr/^\d+$/ },
                stopLoss    =>  { type => SCALAR, callbacks => { v => \&_isPositiveNum } },
                orderID     =>  { type => SCALAR },
                rate        =>  { type => SCALAR, callbacks => { v => \&_isPositiveNum } },
                now         =>  { type => SCALAR },
                nav         =>  { type => SCALAR, callbacks => { v => \&_isPositiveNum } },
                balance     =>  { type => SCALAR, callbacks => { v => \&_isPositiveNum } },
              }
            );
    $self->$orig(@_);
};

sub open {
    die("overrideme");
}

=item C<close()>

=cut

around 'close' => sub {
    my $orig = shift;
    my $self = shift;

    validate( @_,
              {
                symbol      =>  { type => SCALAR },
                direction   =>  { type => SCALAR, callbacks => { v => \&_isDirection } },
                amount      =>  { type => SCALAR, regex => qr/^\d+$/ },
                currentValue=>  { type => SCALAR, callbacks => { v => \&_isPositiveNum } },
                now         =>  { type => SCALAR },
                nav         =>  { type => SCALAR, callbacks => { v => \&_isPositiveNum } },
                balance     =>  { type => SCALAR, callbacks => { v => \&_isPositiveNum } },
              }
            );
    $self->$orig(@_);
};

sub close {
    die("overrideme");
}


__PACKAGE__->meta->make_immutable;
1;

=back


=head1 LICENSE

This is released under the MIT license. See L<http://www.opensource.org/licenses/mit-license.php>.

=head1 AUTHOR

Joao Costa - L<http://zonalivre.org/>

=head1 SEE ALSO

L<Finance::HostedTrader::Trader>

=cut
