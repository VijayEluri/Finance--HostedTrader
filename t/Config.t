#!/usr/bin/perl

use strict;
use warnings;
use Test::More qw(no_plan);
use Data::Dumper;

BEGIN {
use_ok ('Finance::HostedTrader::Config');
use_ok ('Finance::HostedTrader::Config::DB');
use_ok ('Finance::HostedTrader::Config::Symbols');
use_ok ('Finance::HostedTrader::Config::Timeframes');
}

my $db = Finance::HostedTrader::Config::DB->new(
		'dbhost' => 'dbhost',
		'dbname' => 'dbname',
		'dbuser' => 'dbuser',
		'dbpasswd'=> 'dbpasswd',
	);
isa_ok($db,'Finance::HostedTrader::Config::DB');

my $symbols = Finance::HostedTrader::Config::Symbols->new(
		'natural' => [ qw (AUDUSD USDJPY) ],
	);
isa_ok($symbols,'Finance::HostedTrader::Config::Symbols');

my $timeframes = Finance::HostedTrader::Config::Timeframes->new(
		'natural' => [ qw (300 60) ], #Make sure timeframes are unordered to test if the module returns them ordered
	);
isa_ok($symbols,'Finance::HostedTrader::Config::Symbols');

my $config = Finance::HostedTrader::Config->new( 'db' => $db, 'symbols' => $symbols, 'timeframes' => $timeframes );
is($config->db->dbhost, 'dbhost', 'db host');
is($config->db->dbname, 'dbname', 'db name');
is($config->db->dbuser, 'dbuser', 'db user');
is($config->db->dbpasswd, 'dbpasswd', 'db passwd');
is_deeply($config->symbols->synthetic, [], 'empty synthetic symbols');
is_deeply($config->symbols->all(), [qw(AUDUSD USDJPY)], 'symbols');
is_deeply($config->timeframes->synthetic, [], 'empty synthetic timeframes');
is_deeply($config->timeframes->natural(), [qw(60 300)], 'ordered natural timeframes');
is_deeply($config->timeframes->all(), [qw(60 300)], 'ordered all timeframes');

my $config_file = Finance::HostedTrader::Config->new();
isa_ok($config_file,'Finance::HostedTrader::Config');
