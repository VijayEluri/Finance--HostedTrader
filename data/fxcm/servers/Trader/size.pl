#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

use Finance::HostedTrader::Account;
use Systems;

my $positions = [
    {   symbol => 'AUDUSD', direction => 'long' },
    {   symbol => 'USDCAD', direction => 'short' },
];


my $account = Finance::HostedTrader::Account->new(
                address => '127.0.0.1',
                port => '1500',
              );

my $system = Systems->new( name => 'trendfollow' );
my $accountSize = $account->getNav();


print "Account Size: $accountSize\n";

foreach my $position (@$positions) {

    my ($pos_size, $entry, $exit);
    eval {
       ($pos_size, $entry, $exit) = $system->getTradeSize($account, $position->{symbol}, $position->{direction});
       1;
    } or do {
        print $@;
       ($pos_size, $entry, $exit) = ('', '', '');
    };
    print qq|
Symbol: $position->{symbol}
Direction: $position->{direction}
Entry: $entry
Stop: $exit
Position Size: $pos_size
|;

}
