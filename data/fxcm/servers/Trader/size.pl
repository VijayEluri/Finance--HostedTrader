#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Getopt::Long qw(:config pass_through);
use Pod::Usage;

use Finance::HostedTrader::Factory::Account;
use Finance::HostedTrader::Trader;
use Finance::HostedTrader::System;

my $positions = [
    {   symbol => 'EURCAD', direction => 'short' },
    {   symbol => 'GBPCHF', direction => 'long' },
];


my ($verbose, $help, $accountClass, $pathToSystems) = (0, 0, 'ForexConnect', 'systems');
my $result = GetOptions(
    "class=s",          \$accountClass,
    "verbose",          \$verbose,
    "help",             \$help,
    "pathToSystems=s",  \$pathToSystems,
) || pod2usage(2);

pod2usage(1) if ($help);

my $trendfollow = Finance::HostedTrader::System->new( name => 'trendfollow', pathToSystems => $pathToSystems );
my %classArgs = map { s/^--//; split(/=/) } @ARGV;
my $account = Finance::HostedTrader::Factory::Account->new(
                SUBCLASS => $accountClass,
                system => $trendfollow,
                %classArgs,
            )->create_instance();



my $system = Finance::HostedTrader::Trader->new( system => $trendfollow, account => $account );
my $accountSize = $account->getNav();


print "Account Nav: $accountSize\n";

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
