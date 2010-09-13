#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use FXCMServer;

    my $s = FXCMServer->new();

    print $s->getAsk("EURUSD"), "\n";
    print $s->getBid("EURUSD"), "\n";

    my ($openOrderID, $price) = $s->openMarket('EURUSD', 'long', 100000);
    sleep(2); #Wait some time before proceeding otherwise the getTrades call won't return the newly created trade
    my $trades = $s->getTrades();
    print Dumper(\$trades);

    my $tradeID = $trades->[0]->{id};
    my $closeOrderID = $s->closeMarket($tradeID, 100000);
    $trades = $s->getTrades();
    print Dumper(\$trades); #Didn't call sleep this time around, the closed trade was still returned
    sleep(2);
    $trades = $s->getTrades();
    print Dumper(\$trades); #But after a short wait, the trade should be gone
