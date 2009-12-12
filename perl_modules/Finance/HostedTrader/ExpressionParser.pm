package Finance::HostedTrader::ExpressionParser;
use strict;
use warnings;
my (%INDICATORS,%VALUES);

use Parse::RecDescent;
use Finance::HostedTrader::Datasource;


sub checkArgs {
my @rv;
    foreach my $arg (@_) {
		my $value = $arg; #Copy to a different var otherwise values in the caller change as well.

		while ($value =~ /(T(\d+))/) {
			my ($find, $index) = ($1, $2);
			$value =~ s/$find/$VALUES{$index}/g;
			
		}
		push @rv, $value;
    }
return @rv;
}

sub getID {
my @rv = ();

while (my $key = shift) {
	$INDICATORS{$key} = scalar(keys %INDICATORS) unless exists $INDICATORS{$key};
	push @rv, $INDICATORS{$key};
	$VALUES{$INDICATORS{$key}} = $key;
}
return wantarray ? @rv : $rv[$#rv];
}

#$::RD_TRACE=1;
$::RD_HINT=1;
$::RD_WARN=1;
$::RD_ERRORS=1;

sub new {

my ($class, $ds) = @_;
my $grammar_indicators = q {
start:          statement /\Z/               {$item[1]}

statement:		<leftop: expression exp_sep expression > {join(' ', @{$item[1]})} |
				expression

exp_sep:	','

expression:     term '+' expression      {"$item[1] + $item[3]"}
              | term '-' expression      {"$item[1] - $item[3]"}
              | term '*' expression      {"$item[1] * $item[3]"}
              | term '/' expression      {"$item[1] / $item[3]"}
              | term

term:           number
              | field
              | function
              | '(' expression ')'        {"($item[2])"}

number:         /\d+/

field:			"open" | "high" | "low" | "close"

function:
		'ema(' expression ',' number ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); "T".Finance::HostedTrader::ExpressionParser::getID("round(ta_ema($vals[0],$item[4]), 4)") } |
		'sma(' expression ',' number ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); "T".Finance::HostedTrader::ExpressionParser::getID("round(ta_sma($vals[0],$item[4]), 4)") } |
		'rsi(' expression ',' number ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); "T".Finance::HostedTrader::ExpressionParser::getID("round(ta_rsi($vals[0],$item[4]), 2)") } |
		'max(' expression ',' number ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); "T".Finance::HostedTrader::ExpressionParser::getID("ta_max($vals[0],$item[4])") } |
		'min(' expression ',' number ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); "T".Finance::HostedTrader::ExpressionParser::getID("ta_min($vals[0],$item[4])") } |
		'tr(' ')'  { "T".Finance::HostedTrader::ExpressionParser::getID("round(ta_tr(high,low,close), 4)") } |
		'previous(' expression ',' number ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); "T".Finance::HostedTrader::ExpressionParser::getID("ta_previous($vals[0],$item[4])") } |
		'bolhigh(' expression ',' number ',' number ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); my ($t1,$t2) = Finance::HostedTrader::ExpressionParser::getID("ta_sma($vals[0],$item[4])","ta_sum(POW(($vals[0]) - ta_sma($vals[0], $item[4]), 2), $item[4])"); "round(T$t1 + $item[6]*SQRT(T$t2/$item[4]), 4)" } |
		'bollow(' expression ',' number ',' number ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); my ($t1,$t2) = Finance::HostedTrader::ExpressionParser::getID("ta_sma($vals[0],$item[4])","ta_sum(POW(($vals[0]) - ta_sma($vals[0], $item[4]), 2), $item[4])"); "round(T$t1 - $item[6]*SQRT(T$t2/$item[4]), 4)" } |
		'trend(' expression ',' number ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); my ($t1,$t2) = Finance::HostedTrader::ExpressionParser::getID("ta_sma($vals[0],$item[4])","ta_sum(POW($vals[0] - ta_sma($vals[0], $item[4]), 2), $item[4])"); "round(($vals[0] - T$t1) / (SQRT(T$t2/$item[4])), 2)" } |
		'macd(' expression ',' number ',' number ',' number ')' {my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); my ($t1,$t2) = Finance::HostedTrader::ExpressionParser::getID("ta_ema($vals[0],$item[4])", "ta_ema($vals[0],$item[6])");"round(T$t1 - T$t2,4)" } |
		'macdsig(' expression ',' number ',' number ',' number ')' {my @vals=Finance::HostedTrader::ExpressionParser::checkArgs($item[2]);"T".Finance::HostedTrader::ExpressionParser::getID("round(ta_ema(ta_ema($vals[0],$item[4]) - ta_ema($item[2],$item[6]),$item[8]),4)") } |
		'abs(' expression ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); "T".Finance::HostedTrader::ExpressionParser::getID("round(abs($vals[0]), 4)") }
};

my $grammar_signals = q {
start:          statement /\Z/               {$item[1]}

statement:		<leftop: signal boolop signal > {join(' ', @{$item[1]})} |
				signal

boolop:	'AND' | 'OR'


signal:         'crossoverup' '(' expression ',' number ')' {my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[3]);my $t1 = Finance::HostedTrader::ExpressionParser::getID("ta_previous($vals[0],1)");"($item[3] > $item[5] AND T$t1 <= $item[5])"}
			  | 'crossoverup' '(' number ',' expression ')' {my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[5]);my $t1 = Finance::HostedTrader::ExpressionParser::getID("ta_previous($vals[0],1)");"($item[3] > $item[5] AND $item[3] <= T$t1)"}
			  | 'crossoverup' '(' expression ',' expression ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[3],$item[5]);my ($t1,$t2) = Finance::HostedTrader::ExpressionParser::getID("ta_previous($vals[0],1)","ta_previous($vals[1],1)");"($item[3] > $item[5] AND T$t1 <= T$t2)"}
              | 'crossoverdown' '(' expression ',' number ')' {my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[3]);my $t1 = Finance::HostedTrader::ExpressionParser::getID("ta_previous($vals[0],1)");"($item[3] < $item[5] AND T$t1 >= $item[5])"}
			  | 'crossoverdown' '(' number ',' expression ')' {my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[5]);my $t1 = Finance::HostedTrader::ExpressionParser::getID("ta_previous($vals[0],1)");"($item[3] < $item[5] AND $item[3] >= T$t1)"}
			  | 'crossoverdown' '(' expression ',' expression ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[3],$item[5]);my ($t1,$t2) = Finance::HostedTrader::ExpressionParser::getID("ta_previous($vals[0],1)","ta_previous($vals[1],1)");"($item[3] < $item[5] AND T$t1 >= T$t2)"}
              | expression '>' expression      {"$item[1] > $item[3]"}
              | expression '<' expression      {"$item[1] < $item[3]"}
              | expression '>=' expression     {"$item[1] >= $item[3]"}
              | expression '<=' expression     {"$item[1] <= $item[3]"}
              | expression

expression:     term '+' expression      {"$item[1] + $item[3]"}
              | term '-' expression      {"$item[1] - $item[3]"}
              | term '*' expression      {"$item[1] * $item[3]"}
              | term '/' expression      {"$item[1] / $item[3]"}
              | term

term:           number
              | field
              | function
              | '(' statement ')'        {"($item[2])"}

number:         /\d+/

field:			"open" | "high" | "low" | "close"

function:
		'ema(' expression ',' number ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); "T".Finance::HostedTrader::ExpressionParser::getID("round(ta_ema($vals[0],$item[4]), 4)") } |
		'sma(' expression ',' number ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); "T".Finance::HostedTrader::ExpressionParser::getID("round(ta_sma($vals[0],$item[4]), 4)") } |
		'rsi(' expression ',' number ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); "T".Finance::HostedTrader::ExpressionParser::getID("round(ta_rsi($vals[0],$item[4]), 2)") } |
		'max(' expression ',' number ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); "T".Finance::HostedTrader::ExpressionParser::getID("ta_max($vals[0],$item[4])") } |
		'min(' expression ',' number ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); "T".Finance::HostedTrader::ExpressionParser::getID("ta_min($vals[0],$item[4])") } |
		'tr(' ')'  { "T".Finance::HostedTrader::ExpressionParser::getID("round(ta_tr(high,low,close), 4)") } |
		'previous(' expression ',' number ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); "T".Finance::HostedTrader::ExpressionParser::getID("ta_previous($vals[0],$item[4])") } |
		'bolhigh(' expression ',' number ',' number ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); my ($t1,$t2) = Finance::HostedTrader::ExpressionParser::getID("ta_sma($vals[0],$item[4])","ta_sum(POW(($vals[0]) - ta_sma($vals[0], $item[4]), 2), $item[4])"); "round(T$t1 + $item[6]*SQRT(T$t2/$item[4]), 4)" } |
		'bollow(' expression ',' number ',' number ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); my ($t1,$t2) = Finance::HostedTrader::ExpressionParser::getID("ta_sma($vals[0],$item[4])","ta_sum(POW(($vals[0]) - ta_sma($vals[0], $item[4]), 2), $item[4])"); "round(T$t1 - $item[6]*SQRT(T$t2/$item[4]), 4)" } |
		'trend(' expression ',' number ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); my ($t1,$t2) = Finance::HostedTrader::ExpressionParser::getID("ta_sma($vals[0],$item[4])","ta_sum(POW($vals[0] - ta_sma($vals[0], $item[4]), 2), $item[4])"); "(round($vals[0] - T$t1) / (SQRT(T$t2/$item[4]),2))" } |
		'macd(' expression ',' number ',' number ',' number ')' {my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); my ($t1,$t2) = Finance::HostedTrader::ExpressionParser::getID("ta_ema($vals[0],$item[4])", "ta_ema($vals[0],$item[6])");"round(T$t1 - T$t2, 4)" } |
		'macdsig(' expression ',' number ',' number ',' number ')' {my @vals=Finance::HostedTrader::ExpressionParser::checkArgs($item[2]);"T".Finance::HostedTrader::ExpressionParser::getID("round(ta_ema(ta_ema($vals[0],$item[4]) - ta_ema($item[2],$item[6]),$item[8]),2)") }
};

my $parser_indicators=Parse::RecDescent->new($grammar_indicators);
my $parser_signals=Parse::RecDescent->new($grammar_signals);

my $self = { 
		'_parser_i' => $parser_indicators,
		'_parser_s' => $parser_signals,
		'_ds' => ( $ds ? $ds : Finance::HostedTrader::Datasource->new()),
		'_cache' => {},
		 };

return bless($self, $class);
}

sub getIndicatorData {
my ($self, $args) = @_;

#Handle arguments
my $tf = $args->{tf} || 'day';
$tf = $self->{_ds}->getTimeframeID($tf) || die("Could not understand timeframe " . ($args->{tf} || 'day'));
my $maxLoadedItems = $args->{maxLoadedItems};
$maxLoadedItems = 10_000_000_000 if (!defined($args->{maxLoadedItems}) || $args->{maxLoadedItems} == -1);
my $itemCount = $args->{maxDisplayItems} || $maxLoadedItems;
my $expr = $args->{expr} || die("No expression set");
my $symbol = $args->{symbol} || die("No symbol set");

my ($result, $select_fields);
my $cache = $self->{_cache}->{$expr};
if (defined($cache)) {
	($result, $select_fields) = ($cache->{result}, $cache->{select_fields});
} else {
#Reset the global variable the parser uses to store information
#TODO: This shouldn't be global, I ought to have one of these per call
#TODO: Refactor the parser bit so that it can be called independently. This will be usefull to validate expressions before running them.
%INDICATORS = ();
$result = $self->{_parser_i}->start($expr);
#TODO: Need a more meaningfull error message describing what's wrong with the given expression
die("Syntax error in indicator \n\n$expr\n") unless(defined($result));
my @fields = map {"$_ AS T$INDICATORS{$_}"} keys %INDICATORS;
$select_fields = join(', ', @fields);
$self->{_cache}->{$expr} = {'result' => $result, 'select_fields' => $select_fields};
}

$result = ",$result" if($result);
$select_fields = ','.$select_fields if ($select_fields);

my $WHERE_FILTER='';
$WHERE_FILTER = 'WHERE dayofweek(datetime) <> 1' if ($tf != 604800);

my $sql = qq(
SELECT datetime$result FROM (
SELECT *$select_fields
FROM (
    SELECT * FROM (
        SELECT * FROM $symbol\_$tf
        $WHERE_FILTER
        ORDER BY datetime desc
        LIMIT $maxLoadedItems
    ) AS T_LIMIT
    ORDER BY datetime
) AS T_INNER
) AS T_OUTER
);

my $dbh = $self->{_ds}->{dbh};
my $sth = $dbh->prepare($sql) or die($DBI::errstr.$sql);
$sth->execute() or die($DBI::errstr.$sql);
my $data = $sth->fetchall_arrayref;
$sth->finish() or die($DBI::errstr);
    my $lastItemIndex = scalar(@$data) - 1;
    if (defined($itemCount) && ($lastItemIndex > $itemCount )) {
        my @slice = @{$data}[$lastItemIndex - $itemCount + 1..$lastItemIndex];
        return \@slice;
    }
return $data;
}

sub getSignalData {
my ($self, $args) = @_;
my $tf = $args->{tf} || 'day';
$tf = $self->{_ds}->getTimeframeID($tf) || die("Could not understand timeframe " . ($args->{tf} || 'day'));
my $expr = $args->{expr} || die("No expression set");
my $symbol = $args->{symbol} || die("No symbol set");


%INDICATORS = ();
my $result = $self->{_parser_s}->start($args->{expr});
die("Syntax error in signal \n\n$expr\n") unless(defined($result));

my @fields = map {"$_ AS T$INDICATORS{$_}"} keys %INDICATORS;
my $select_fields = join(', ', @fields);
$select_fields = ','.$select_fields if ($select_fields);

my $WHERE_FILTER='';
$WHERE_FILTER = 'WHERE dayofweek(datetime) <> 1' if ($tf != 604800);

my $sql = qq(
SELECT datetime FROM (
SELECT *$select_fields
FROM (
    SELECT *
    FROM $args->{symbol}\_$tf
    $WHERE_FILTER
    ORDER BY datetime
) AS T_INNER
) AS T_OUTER
WHERE $result
);

my $dbh = $self->{_ds}->{dbh};
my $sth = $dbh->prepare($sql) or die($DBI::errstr.$sql);
$sth->execute() or die($DBI::errstr.$sql);
my $data = $sth->fetchall_arrayref;
$sth->finish() or die($DBI::errstr);
return [ map {$_->[0]} @$data ];
}

1;
