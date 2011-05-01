#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

use Finance::HostedTrader::DB::Trader::Schema;
use Finance::HostedTrader::ExpressionParser;
use DateTime;

my $signals_model = Finance::HostedTrader::DB::Trader::Schema->resultset('Signal');

my $debug = 0;
my $signal_processor = Finance::HostedTrader::ExpressionParser->new();


my $signals_rs = $signals_model->alerts();

while ( my $signal = $signals_rs->next() ) {
    my @alerts = $signal->signals_alerts;
    foreach my $alert (@alerts) {
        my $data = $signal_processor->checkSignal(
            {   symbol => $alert->symbol,
                tf => $signal->timeframe,
                expr => $signal->definition,
                debug => $debug,
                period => $signal->period,
            } );
        if ($data) {
            print $alert->symbol . " " . $signal->direction . "\n";
            $alert->detectedon(DateTime->now);
            $alert->update();
        }
    }
}
