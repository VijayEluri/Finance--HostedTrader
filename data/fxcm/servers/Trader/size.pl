#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

use Finance::HostedTrader::Account;
use Systems;

my $positions = [
    {   symbol => 'XAGUSD', direction => 'long' },
    {   symbol => 'EURJPY', direction => 'short' },
    {   symbol => 'USDCHF', direction => 'short' },
];


my $account = Finance::HostedTrader::Account->new(
                username => 'none',
                password => 'not implemented',
              );

my $system = Systems->new( name => 'trendfollow' );
my $accountSize = $account->getNav();


print "Account Size: $accountSize\n";

foreach my $position (@$positions) {

    my ($pos_size, $entry, $exit) = $system->getTradeSize($account, $position->{symbol}, $position->{direction});
    print qq|
Symbol: $position->{symbol}
Direction: $position->{direction}
Entry: $entry
Stop: $exit
Position Size: $pos_size
|;

}
