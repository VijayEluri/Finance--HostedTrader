#!/usr/bin/perl
package Finance::HostedTrader;

use strict;
use warnings;

use Finance::HostedTrader::Config;
use Data::Dumper;

my $cfg = Finance::HostedTrader::Config->new();
print Dumper(\$cfg);
