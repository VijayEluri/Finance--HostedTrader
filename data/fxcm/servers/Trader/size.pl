#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;

use Finance::HostedTrader::Account;
use Systems;

my $positions = [
    {   symbol => 'AUDUSD', direction => 'long' },
    {   symbol => 'USDCAD', direction => 'short' },
];


my ($address, $port) = ('127.0.0.1', 1500);

GetOptions(
    "address=s" => \$address,
    "port=i"    => \$port,
);

my $account = Finance::HostedTrader::Account->new(
                address => $address,
                port => $port,
              );

my $system = Systems->new( name => 'trendfollow', account => $account );
my $accountSize = $account->getNav();


print "Account Size: $accountSize\n";

foreach my $position (@$positions) {

    my ($pos_size, $entry, $exit);
    eval {
       ($pos_size, $entry, $exit) = $system->getTradeSize($position->{symbol}, $position->{direction});
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
