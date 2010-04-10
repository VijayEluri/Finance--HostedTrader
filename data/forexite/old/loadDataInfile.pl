#!/usr/bin/perl -w

use strict;
use Cwd;
use GT::Conf;
use GT::DateTime;
use GT::Eval;
use File::Find;
use File::Basename;

setpriority 0, 0, 19;

my $verbose=0;
my $timeframe = shift or die(usage());
GT::Conf::load();

my $db = create_standard_object("DB::" . GT::Conf::get('DB::module'));
my $dbh=$db->{_dbh};

find(\&handleFile, '.');



sub handleFile {
return unless (/\.$timeframe$/);
my $filename=basename($_);
my ($symbol,$ignore_ext) = split(/\./, $filename);

my $numTf = GT::DateTime::name_to_timeframe($timeframe);

my $dir=cwd();
my $sql = "load data infile '$dir/$symbol.$timeframe' replace into table `$symbol\_$numTf` fields terminated by ',';\n";
$dbh->do($sql) or die("Error executing statment:\n\n$sql\n\n".$dbh->errstr."\n");
warn "$0 $symbol $timeframe\n" if ($verbose);
}

sub usage {
return "Searches for all files in current directory ending in .TIMEFRAME, and loads those into the database.\nIf a file name EURUSD.hour exists, and the script is called as in '$0 hour', that file will be loaded into the EURUSD table.\n\nUsage:\n\t$0 TIMEFRAME\n";
}
