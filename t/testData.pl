#!/usr/bin/perl

use strict;
use warnings;

=pod
Tests for the presence of invalid period data in the dataset.

Invalid records include:
 - High < Low
 - High < Close
 - Low > Close
 - High < Open
 - Low > Open
=cut

use Finance::HostedTrader::Config;
use Finance::HostedTrader::Datasource;
use Data::Dumper;
use Test::More qw(no_plan);

my $cfg = Finance::HostedTrader::Config->new();
my $ds = Finance::HostedTrader::Datasource->new();
my $dbh = $ds->dbh;

my $symbols = $cfg->symbols->all;
my $timeframes = $cfg->timeframes->all;


foreach my $tf (@$timeframes) {
    foreach my $symbol (@$symbols) {
        my $sql = qq |
SELECT datetime, open, high, low, close
FROM $symbol\_$tf
WHERE high < low OR high < close OR low > close OR high < open OR low > open
|;
    my $sth = $dbh->prepare($sql) or die($DBI::errstr);
    $sth->execute() or die($DBI::errstr);

    my $data = $sth->fetchall_arrayref();
    $sth->finish() or die($DBI::errstr);

    is(scalar(@$data), 0, "Invalid records in $symbol\_$tf");
    if (scalar(@$data) > 0) {
        print Dumper(\$data);
    }
    }
}