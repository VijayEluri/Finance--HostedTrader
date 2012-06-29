#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;
use Test::Exception;
use Data::Dumper;

BEGIN {
    use_ok ('Finance::HostedTrader::Account::FXCM::ForexConnect');
}
