#!/usr/bin/perl 

use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;
use Finance::HostedTrader::Datasource;

my ($verbose) = (0);

my $db = Finance::HostedTrader::Datasource->new();
my $symbols = $db->getNaturalSymbols;
my $synthetics = $db->getSyntheticSymbols;

my $symbols_txt;
my $result = GetOptions(
                        "symbols=s", \$symbols_txt,
                        "verbose", \$verbose
                        );
$synthetics = [ split(',', $symbols_txt) ] if ($symbols_txt);

foreach my $synthetic (@$synthetics) {
my $sym1 = substr($synthetic,0,3);
my $sym2 = substr($synthetic,3,3);
my $search1=$sym1.'USD';
my $search2='USD'.$sym1;
my @u1 = grep(/$search1|$search2/, @$symbols);

$search1=$sym2.'USD';
$search2='USD'.$sym2;
my @u2 = grep(/$search1|$search2/, @$symbols);
my $op;
my ($low,$high);
if ($u1[0] =~ /USD$/ && $u2[0] =~ /^USD/) {
  $op = '*';
  $low='low';$high='high';
} elsif ($u1[0] =~ /USD$/ && $u2[0] =~ /USD$/) {
  $op = '/';
  $low='high';$high='low';
} elsif ($u1[0] =~ /^USD/ && $u2[0] =~ /^USD/) {
  $op = '/';
  $low='high';$high='low';
  my $tmp = $u1[0];
  $u1[0] = $u2[0];
  $u2[0] = $tmp;
} else {
  warn "Don't know how to handle $synthetic [] synthetic pair\n";
  next;
}

my $filter = ' AND T1.datetime > DATE_SUB(NOW(), INTERVAL 2 WEEK)';

print "$synthetic $u1[0] $op $u2[0]\n" if ($verbose);
my $sql = "insert ignore into $synthetic\_60 (select T1.datetime, round(T1.open".$op."T2.open,4) as open, round(T1.low".$op."T2.$low,4) as low, round(T1.high".$op."T2.$high,4) as high, round(T1.close".$op."T2.close,4) as close from $u1[0]\_60 as T1, $u2[0]\_60 as T2 WHERE T1.datetime = T2.datetime $filter)";

$db->{dbh}->do($sql);

}
