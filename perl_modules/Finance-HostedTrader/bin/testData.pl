#!/usr/bin/perl
package Finance::HostedTrader::DataManager;
# ABSTRACT: Test dataset for error conditions

use strict;
use warnings;

=pod
Tests for :

- datasets with no data

- presence of invalid period data in the dataset.

  Invalid records include:
   - High < Low
   - High < Close
   - Low > Close
   - High < Open
   - Low > Open
=cut

use Finance::HostedTrader::Datasource;
use Data::Dumper;
use Test::More;


my $ds = Finance::HostedTrader::Datasource->new();
my $cfg = $ds->cfg;
my $dbh = $ds->dbh;

my $symbols = $cfg->symbols->all;
my $timeframes = $cfg->timeframes->all;

plan tests => scalar(@$symbols) * scalar(@$timeframes) * 2;

foreach my $tf (@$timeframes) {
    foreach my $symbol (@$symbols) {
        my $sql = qq|
SELECT Count(1) FROM $symbol\_$tf
|;
        my $numRecords = $dbh->selectcol_arrayref($sql);
        isnt($numRecords->[0], 0, "Records exit in $symbol\_$tf");


        $sql = qq |
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
