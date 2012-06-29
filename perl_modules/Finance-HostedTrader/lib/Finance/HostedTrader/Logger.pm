package Finance::HostedTrader::Logger;
# ABSTRACT: Finance::HostedTrader::Logger - A logger object which Finance::HostedTrader classes can inherit.

use strict;
use warnings;
use Moose;
use Log::Log4perl qw(:easy);


has 'logger' => (
    is      => 'ro',
    isa     => 'Any',
    lazy    => 1,
    builder => '_get_logger',
);


sub BUILD {
    my $self = shift;

    if (!Log::Log4perl->initialized()) {
        if ( -r "/etc/hostedtrader.log.conf" ) {
            Log::Log4perl->init("/etc/hostedtrader.log.conf");
        }
    }
}

sub _get_logger {
    return Log::Log4perl::get_logger();
}


1;
