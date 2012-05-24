#!/usr/bin/perl

use strict;
use warnings;

#use Test::More;
use Data::Dumper;

my %limits = (
    300     => 450,
    900     => 2500,
    1800    => 2500,
);

use Finance::HostedTrader::Datasource;

    my $ds          = Finance::HostedTrader::Datasource->new();
    my $cfg         = $ds->cfg;
    my $dbh         = $ds->dbh;

    my $total_tests = 0;

    checkSymbols('natural');
    checkSymbols('synthetic');

sub checkSymbols {
    my $type=shift;

    my $symbols = $cfg->symbols->$type;
    my $timeframes = $cfg->timeframes->all;

    $total_tests += scalar(@$symbols) * scalar(@$timeframes);

    foreach my $symbol (@$symbols) {
        foreach my $tf (@$timeframes) {
            my $limit = $limits{$tf} || $tf*1.2;
            my $sql = qq|
SELECT UNIX_TIMESTAMP(UTC_TIMESTAMP()) - UNIX_TIMESTAMP(MAX(datetime))
FROM $symbol\_$tf
HAVING UNIX_TIMESTAMP(UTC_TIMESTAMP()) - UNIX_TIMESTAMP(MAX(datetime)) > $limit
|;
            my $data = $dbh->selectrow_arrayref($sql);
            #is($data, undef, "$symbol($type)\t$tf");
            print "$symbol($type)\t$tf\t$limit\t".Dumper(\$data)."\n" if ($data);
        }
    }
}

#done_testing($total_tests);
