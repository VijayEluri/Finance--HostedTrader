#!/usr/bin/perl

use strict;
use warnings;

use Finance::HostedTrader::Datasource;
use Data::Dumper;
use Test::More qw(no_plan);

my $ds = Finance::HostedTrader::Datasource->new();
my $dbh = $ds->{dbh};

my $symbols = $ds->getAllSymbols;
my $timeframes = $ds->getSyntheticTimeframes;


foreach my $tf (@$timeframes) {
    foreach my $symbol (@$symbols) {
        my $sql = qq |
SELECT datetime
FROM $symbol\_$tf
WHERE high < low OR high < close OR low > close OR high < open OR low > open
|;
    my $sth = $dbh->prepare($sql) or die($DBI::errstr);
    $sth->execute() or die($DBI::errstr);

    my $data = $sth->fetchall_arrayref();
    $sth->finish() or die($DBI::errstr);

    is(scalar(@$data), 0, "$symbol\_$tf");
    }
}
