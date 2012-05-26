#!/usr/bin/perl
package Finance::HostedTrader;
# ABSTRACT: Outputs the configuration that applies if when a Finance::HostedTrader script is run from the current working directory, including merging of multiple config files.

use strict;
use warnings;

use Finance::HostedTrader::Config;
use Data::Dumper;

my $cfg = Finance::HostedTrader::Config->new();
print Dumper(\$cfg);
