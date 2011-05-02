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
    my $i=30; #retrieves 31 days worth of data

    my $val = $mul{$tf};
    my @dates;
    do {
        my ($start, $end) = ( UnixDate( $i*$val . " days ago", "%Y-%m-%d" ), UnixDate( ($i-1)*$val." days ago", "%Y-%m-%d" ) );
        push @dates, "$start|$end";
    } while ($i-- > 0);
    print "$tf;" . join(',', @dates) . " ";

}
