#!/usr/bin/perl -w

use strict;
use Cwd;
use File::Find;
use File::Basename;

setpriority 0, 0, 19;

my $verbose=0;
my $timeframe = shift or die(usage());

my $dbh=undef;

find(\&handleFile, '.');



sub handleFile {
return unless (/\.$timeframe$/);
my $filename=basename($_);
my ($symbol,$ignore_ext) = split(/\./, $filename);

my $numTf = 60;

my $dir=cwd();
my $file = "$dir/$symbol.$timeframe";
open DATA, "<$file" or die("Cannot open $file for reading\n");
while (<DATA>) {
chomp();
my ($date,$v1,$v2,$v3,$v4) = split(',');
my $sql = "replace into $symbol\_$numTf values('$date',$v1,$v2,$v3,$v4);\n";
$dbh->do($sql) or die("Error executing statment:\n\n$sql\n\n".$dbh->errstr."\n");
}
close(DATA);
warn "$0 $symbol $timeframe\n" if ($verbose);
}

sub usage {
return "Searches for all files in current directory ending in .TIMEFRAME, and loads those into the database.\nIf a file name EURUSD.hour exists, and the script is called as in '$0 hour', that file will be loaded into the EURUSD table.\n\nUsage:\n\t$0 TIMEFRAME\n";
}
