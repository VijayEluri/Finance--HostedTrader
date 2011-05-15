package Finance::HostedTrader::Trader::Notifier::Production;
=head1 NAME

    Finance::HostedTrader::Notifier - Notifier object

=head1 SYNOPSIS

    use Finance::HostedTrader::Notifier::Production;
    my $obj = Finance::HostedTrader::Notifier::Production->new(
                );

=head1 DESCRIPTION


=cut


use strict;
use warnings;

use Moose;
extends 'Finance::HostedTrader::Trader::Notifier';
use MIME::Lite;

=head2 Properties

=over 12

=back

=head2 Constructor

=over 12

=item C<BUILD>

Constructor.

=cut
sub BUILD {
    my $self = shift;

}

=back


=head2 METHODS


=over 12


=item C<open($trade)>

=cut
sub open {
    my $self = shift;
    my %args=@_;

    my $symbol      = $args{symbol};
    my $direction   = $args{direction};
    my $amount      = $args{amount};
    my $stopLoss    = $args{stopLoss};
    my $orderID     = $args{orderID};
    my $rate        = $args{rate};
    

    $self->_sendMail('Trading Robot - Open Trade ' . $symbol, qq {Open Trade:
Instrument: $symbol
Amount: $amount
Open Price: $rate
Stop Loss: $stopLoss
            });
}

=item C<close()>

=cut
sub close {
    my $self = shift;
    my %args=@_;

    my $symbol      = $args{symbol};
    my $direction   = $args{direction};
    my $amount      = $args{amount};
    my $value       = $args{currentValue};
    
    $self->_sendMail('Trading Robot - Close Trade ' . $symbol, qq {Close Trade:
Instrument: $symbol
Direction: $direction
Position Size: $amount
Current Value: $value
    });
}

sub _sendMail {
my ($self, $subject, $content) = @_;
use MIME::Lite;

    #$self->logger($content);
    ### Create a new single-part message, to send a GIF file:
    my $msg = MIME::Lite->new(
        From     => 'fxhistor@fxhistoricaldata.com',
        To       => 'joaocosta@zonalivre.org',
        Subject  => $subject,
        Data     => $content
    );
    $msg->send; # send via default
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
