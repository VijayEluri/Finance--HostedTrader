package Finance::HostedTrader::Trader::Notifier;
# ABSTRACT: Finance::HostedTrader::Notifier - Notifier object

=head1 SYNOPSIS

    use Finance::HostedTrader::Notifier;
    my $obj = Finance::HostedTrader::Notifier->new(
                );

=cut


use strict;
use warnings;

use Moose;
use Params::Validate qw(:all);
use Scalar::Util;

=method C<open()>

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

=method C<close()>

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

=head1 SEE ALSO

L<Finance::HostedTrader::Trader>

=cut
