#!/usr/bin/perl -w

use strict;
use warnings;
use Time::Local;


my $ONEDAY=24*60*60;

my $lastdate;
while(<STDIN>) {$lastdate=$_;};
chomp($lastdate);

my ($i1,$i2,$i3,$i4,$year,$mon,$mday) = split('/', $lastdate);
$mday=substr($mday,0,2);


my $today=timelocal(localtime);


my $epochLastdate=timelocal(59,59,23,$mday,int($mon)-1,$year-1900)+$ONEDAY;

do {
my ($seconds,$minutes,$hours,$day_of_month,$month,$year,$wday,$yday,$isdst)=localtime($epochLastdate);
$year+=1900;
$month++;
$month=stuff($month);
$day_of_month=stuff($day_of_month);
my $shortyear=stuff($year-2000);
print "http://www.forexite.com/free_forex_quotes/$year/$month/$day_of_month$month$shortyear.zip\n";
$epochLastdate+=$ONEDAY;
} while ($epochLastdate < $today);

sub stuff {
my $v=shift;

return "0".$v if (length($v)==1);
return $v;
}
