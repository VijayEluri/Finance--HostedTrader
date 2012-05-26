#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 25;
use Data::Dumper;
use File::Basename;

BEGIN {
use_ok ('Finance::HostedTrader::Config');
use_ok ('Finance::HostedTrader::Config::DB');
use_ok ('Finance::HostedTrader::Config::Symbols');
use_ok ('Finance::HostedTrader::Config::Timeframes');
}


my $t_path = dirname($0);

my $merge_files = Finance::HostedTrader::Config->new(
		'files' => [
			"$t_path/cfg1.yml",
			"$t_path/cfg2.yml", ]);

isa_ok($merge_files,'Finance::HostedTrader::Config');
is($merge_files->db->dbhost, 'dbhost', 'Key missing in file cfg2');
is($merge_files->db->dbname, 'dbname2', 'Key present in both files');
is($merge_files->db->dbpasswd, undef, 'Key present in both files but undefined in cfg2');
is_deeply($merge_files->symbols->synthetic, ['XAGJPY'], 'Key missing in file cfg2');
is_deeply($merge_files->symbols->natural, ['XAGUSD2'], 'Key missing in file cfg1');
is_deeply($merge_files->timeframes->synthetic, [], 'Key present in both files but empty list in cfg2');
is_deeply($merge_files->timeframes->natural, [300], 'Key present in both files as list reference');

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
isa_ok($timeframes,'Finance::HostedTrader::Config::Timeframes');

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
