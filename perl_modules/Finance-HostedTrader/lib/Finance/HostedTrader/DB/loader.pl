#!/usr/bin/perl

use strict;
use warnings;

use DBIx::Class::Schema::Loader qw/ make_schema_at /;

my $database = 'trader';
my $username = 'fxhistor';
my $password = undef;


make_schema_at(
    'Finance::HostedTrader::DB::Trader::Schema',
    {   use_namespaces  => 1,
        dump_directory  => '../../..',
    },
    [ "dbi:mysql:dbname=$database", $username, $password ],
);
