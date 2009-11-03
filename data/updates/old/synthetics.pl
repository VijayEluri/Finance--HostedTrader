#!/usr/bin/perl -w

use strict;
use Cwd;
use GT::Conf;
use GT::Eval;
use Getopt::Long;

setpriority 0, 0, 19;

GT::Conf::load();

my $datafeed=GT::Conf::get('datafeed');
my $synthetics_txt = GT::Conf::get("datafeed::$datafeed\::synthetics");
my $all_recs = 0;
my $verbose = 0;

my $result = GetOptions("symbols=s", \$synthetics_txt,
			"all", \$all_recs, "verbose", \$verbose);

my @symbols = split(',', GT::Conf::get('datafeed::'.GT::Conf::get('datafeed').'::symbols'));
my @synthetics = split(',', $synthetics_txt);

my $db = create_standard_object("DB::" . GT::Conf::get('DB::module'));
my $dbh=$db->{_dbh};

foreach my $synthetic (@synthetics) {
print "$synthetic\n" if($verbose);
my $sym1 = substr($synthetic,0,3);
my $sym2 = substr($synthetic,3,3);
my $search1=$sym1.'USD';
my $search2='USD'.$sym1;
my @u1 = grep(/$search1|$search2/, @symbols);

$search1=$sym2.'USD';
$search2='USD'.$sym2;
my @u2 = grep(/$search1|$search2/, @symbols);
my $op;
my ($low,$high);
if ($u1[0] =~ /USD$/ && $u2[0] =~ /^USD/) {
  $op = '*';
  $low='low';$high='high';
} elsif ($u1[0] =~ /USD$/ && $u2[0] =~ /USD$/) {
  $op = '/';
  $low='high';$high='low';
} elsif ($u1[0] =~ /^USD/ && $u2[0] =~ /^USD/) {
  $op = '/';
  $low='high';$high='low';
  my $tmp = $u1[0];
  $u1[0] = $u2[0];
  $u2[0] = $tmp;
} else {
  warn "Don't know how to handle $synthetic [] synthetic pair\n";
  next;
}
warn "$synthetic $u1[0] $op $u2[0]\n" if ($all_recs);
my $sql;
if ($all_recs) {
$sql = "insert ignore into $synthetic\_10 (select T1.datetime, round(T1.open".$op."T2.open,4) as open, round(T1.low".$op."T2.$low,4) as low, round(T1.high".$op."T2.$high,4) as high, round(T1.close".$op."T2.close,4) as close from $u1[0]\_10 as T1, $u2[0]\_10 as T2 WHERE T1.datetime = T2.datetime)";
} else {
$sql = "insert ignore into $synthetic\_10 (select T1.datetime, round(T1.open".$op."T2.open,4) as open, round(T1.low".$op."T2.$low,4) as low, round(T1.high".$op."T2.$high,4) as high, round(T1.close".$op."T2.close,4) as close from $u1[0]\_10 as T1, $u2[0]\_10 as T2 WHERE T1.datetime = T2.datetime and T1.datetime > DATE_SUB(NOW(), INTERVAL 1 month))";
}

$dbh->do($sql) or die("Error executing statment:\n\n$sql\n\n".$dbh->errstr."\n");
}

#EURAUD
#EURUSD/AUDUSD
#AUDCHF
#AUDUSD*USDCHF

#AUDGBP
#AUDUSD/GBPUSD

#EURNZD
#EURUSD/NZDUSD



sub usage {
return "Handles synthetic pairs\n";
}
