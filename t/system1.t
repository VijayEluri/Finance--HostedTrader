#!/usr/bin/perl

use strict;
use warnings;
use YAML::Tiny;

my $ENV=$ENV{HARNESS_PERL_SWITCHES} || '';
my $systemName = 'trendfollow';

my $yml = YAML::Tiny->new;
$yml->[0] = {
	name => $systemName,
	filters => {
		symbols => {
			long => [],
			short => [ qw/USDJPY/ ],
		}
	}
};

$yml->write("systems/$systemName.tradeable.yml") || die($!);
if (-e "systems/$systemName.symbols.yml" ) { unlink("systems/$systemName.symbols.yml") || die($!); }
system('perl '.$ENV.' ../data/fxcm/servers/Trader/Trader.pl --class=UnitTest --notifier=UnitTest --startDate="2010-08-18 06:00:00" --endDate="2010-09-17 00:00:00" --expectedTradesFile=trader/trades.jpy');
