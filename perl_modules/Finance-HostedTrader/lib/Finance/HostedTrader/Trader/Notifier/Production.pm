package Finance::HostedTrader::Trader::Notifier::Production;
# ABSTRACT: Finance::HostedTrader::Notifier - Notifier object

=head1 SYNOPSIS

    use Finance::HostedTrader::Notifier::Production;
    my $obj = Finance::HostedTrader::Notifier::Production->new(
                );

=cut


use strict;
use warnings;

use Moose;
extends 'Finance::HostedTrader::Trader::Notifier';
use MIME::Lite;

=method C<open($trade)>

open trade notifier. Receives a L<Finance::HostedTrader::Trade> object representing the trade that was opened.

Sends an email with information about the trade.

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

=method C<close()>

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
        To       => 'joaocosta@zonalivre.org', #TODO: Hardcoded, needs to be parameterized as a class attribute
        Subject  => $subject,
        Data     => $content
    );
    $msg->send; # send via default
}

__PACKAGE__->meta->make_immutable;
1;
