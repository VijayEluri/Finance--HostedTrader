#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;

use Finance::HostedTrader::Factory::Account;
use Finance::HostedTrader::SystemTrader;
use Finance::HostedTrader::System;
use Finance::HostedTrader::Report;


my ($address, $port, $class, $format) = ('127.0.0.1', 1500, 'FXCM', 'text');

GetOptions(
    "class=s"   => \$class,
    "address=s" => \$address,
    "port=i"    => \$port,
    "format=s"  => \$format,
);


my $trendfollow = Finance::HostedTrader::System->new( name => 'trendfollow' );
my $account = Finance::HostedTrader::Factory::Account->new( SUBCLASS => $class, address => $address, port => $port)->create_instance();
my $systemTrader = Finance::HostedTrader::SystemTrader->new( system => $trendfollow, account => $account );
my $report = Finance::HostedTrader::Report->new( account => $account, systemTrader => $systemTrader, format => $format );
my $nav = $account->getNav();
my $balance = $account->balance();

print "<html><body><p>" if ($format eq 'html');
print "ACCOUNT NAV: " . $nav . "\n\n";
print "ACCOUNT BALANCE: " . $balance . "\n\n";
print "</p>" if ($format eq 'html');
print $report->openPositions;
print "\n";
print $report->systemEntryExit;
print "</body></html>" if ($format eq 'html');
