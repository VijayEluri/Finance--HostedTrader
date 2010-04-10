#!/usr/bin/perl -w


use strict;
use GT::Conf;
use Getopt::Long;

GT::Conf::load();


my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time-24*60*60);

my $datafeed=GT::Conf::get('datafeed');
my $symbols_txt=GT::Conf::get("datafeed::$datafeed\::symbols").','.GT::Conf::get("datafeed::$datafeed\::synthetics");
my $timeframe_txt = 'hour';
my $years_txt=$year+1900;
my $months_txt=$mon+1;
my $verbose=0;

my $result = GetOptions("symbols=s", \$symbols_txt,
			"timeframes=s", \$timeframe_txt,
			"months=s", \$months_txt,
			"years=s", \$years_txt,
			"verbose", \$verbose
			);

my @years=split(',', $years_txt);
my @months=split(',', $months_txt);

my @symbols=split(',',$symbols_txt);
my @timeframes=split(',',$timeframe_txt);


print "#!/bin/sh\n\n";
foreach my $timeframe (@timeframes) {
foreach my $symbol (@symbols) {
print "rm -f $symbol.$timeframe\n";
foreach my $year (@years) {
foreach my $month (@months) {
my $tmp="$year-".stuff($month);
print "./cvtTf.pl $symbol $timeframe '$tmp-01 00:00:00' '$tmp-31 23:59:59' >> $symbol.$timeframe\n";
print "echo $symbol $timeframe $tmp-01 $tmp-31\n" if ($verbose);

}
}
}
}

sub usage {
my $txt = qq/
Wrapper Script simply outputs cvtTf.pl commands to convert
data into a different timeframe.

Default values are:
--symbol	datafeed::(datafeed)::symbols configuration item
--timeframes	hour
--months	current month
--years		current year


Usage:
	$0 [--symbols=sym1,sym2...] [--timeframes=tf1,tf2...] [--months=1,2,3..12] [--years=y1,y2...]
/;
return $txt;
}

sub stuff {
my $v=shift;
return "0$v" if (length($v)==1);
return $v;
}
