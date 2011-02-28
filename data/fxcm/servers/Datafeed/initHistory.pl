#!/usr/bin/perl

use strict;
use warnings;
use Date::Manip;


# This structure has to do with
# the fact we can retrieve up to 300 items of data
my %mul = (
    300 => 1,   # in TF 300(5min), we can have 300*5/60/24 days of data (~= 1 day)
    3600 => 10, # in TF 3600(1hour), we can have 300/24 days of data (~= 10 days)
);

foreach my $tf qw(300 3600) {
    my $i=9;

    my $val = $mul{$tf};
    do {
        my ($start, $end) = ( UnixDate( $i*$val . " days ago at midnight", "%Y-%m-%d" ), UnixDate( ($i-1)*$val." days ago at midnight", "%Y-%m-%d" ) );
        print "wine RatePrinter.exe \"$ENV{FXCM_USER}\" \"$ENV{FXCM_PASSWORD}\" \"$ENV{FXCM_TYPE}\" \"$start\" \"$end\" \"$tf\"\n";
        print "./load $tf\n";
    } while (--$i > 0);

}
