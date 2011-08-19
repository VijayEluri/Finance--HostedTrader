package Finance::HostedTrader::ExpressionParser;
use strict;
use warnings;
use Date::Manip;
my ( %INDICATORS, %VALUES );

use Parse::RecDescent;
use Finance::HostedTrader::Datasource;

sub checkArgs {
    my @rv;
    foreach my $arg (@_) {
        my $value = $arg
          ; #Copy to a different var otherwise values in the caller change as well.

        while ( $value =~ /(T(\d+))/ ) {
            my ( $find, $index ) = ( $1, $2 );
            $value =~ s/$find/$VALUES{$index}/g;

        }
        push @rv, $value;
    }
    return @rv;
}

sub getID {
    my @rv = ();

    while ( my $key = shift ) {
        $INDICATORS{$key} = scalar( keys %INDICATORS )
          unless exists $INDICATORS{$key};
        push @rv, $INDICATORS{$key};
        $VALUES{ $INDICATORS{$key} } = $key;
    }
    return wantarray ? @rv : $rv[$#rv];
}

#$::RD_TRACE=1;
$::RD_HINT   = 1;
$::RD_WARN   = 1;
$::RD_ERRORS = 1;

sub new {

    my ( $class, $ds ) = @_;

    my $grammar = q {
start_indicator:          statement_indicator /\Z/               {$item[1]}

start_signal:          statement_signal /\Z/               {$item[1]}

statement_indicator:		expression(s /,/) {join(',', @{$item[1]})}

statement_signal:		<leftop: signal boolop signal > {join(' ', @{$item[1]})}

statement: statement_indicator | statement_signal

boolop:	'AND' | 'OR'

signal:         
			    'crossoverup' '(' expression ',' expression ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[3],$item[5]);my ($t1,$t2) = Finance::HostedTrader::ExpressionParser::getID("ta_previous($vals[0],1)","ta_previous($vals[1],1)");"($item[3] > $item[5] AND T$t1 <= T$t2)"}
			  | 'crossoverdown' '(' expression ',' expression ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[3],$item[5]);my ($t1,$t2) = Finance::HostedTrader::ExpressionParser::getID("ta_previous($vals[0],1)","ta_previous($vals[1],1)");"($item[3] < $item[5] AND T$t1 >= T$t2)"}
              | expression cmp_op expression      {"$item[1] $item[2] $item[3]"}
              | expression

cmp_op:         '>=' | '>' | '<=' | '<'

expression:     term math_op expression      {"$item[1] $item[2] $item[3]"}
              | term

math_op:        '+' | '-' | '*' | '/'

term:           number
              | field
              | function
              | '(' statement ')'        {"($item[2])"}

number:         /-?\d+(\.\d+)?/

field:			"datetime" | "open" | "high" | "low" | "close"

function:
		'ema(' expression ',' number ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); "T".Finance::HostedTrader::ExpressionParser::getID("round(ta_ema($vals[0],$item[4]), 4)") } |
		'sma(' expression ',' number ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); "T".Finance::HostedTrader::ExpressionParser::getID("round(ta_sma($vals[0],$item[4]), 4)") } |
		'rsi(' expression ',' number ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); "T".Finance::HostedTrader::ExpressionParser::getID("round(ta_rsi($vals[0],$item[4]), 2)") } |
		'max(' expression ',' number ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); "T".Finance::HostedTrader::ExpressionParser::getID("ta_max($vals[0],$item[4])") } |
		'min(' expression ',' number ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); "T".Finance::HostedTrader::ExpressionParser::getID("ta_min($vals[0],$item[4])") } |
		'tr(' ')'  { "T".Finance::HostedTrader::ExpressionParser::getID("round(ta_tr(high,low,close), 4)") } |
		'atr(' number ')'  { "T".Finance::HostedTrader::ExpressionParser::getID("round(ta_ema(ta_tr(high,low,close),$item[2]), 4)") } |
		'previous(' expression ',' number ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); "T".Finance::HostedTrader::ExpressionParser::getID("ta_previous($vals[0],$item[4])") } |
		'bolhigh(' expression ',' number ',' number ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); my ($t1,$t2) = Finance::HostedTrader::ExpressionParser::getID("ta_sma($vals[0],$item[4])","ta_sum(POW(($vals[0]) - ta_sma($vals[0], $item[4]), 2), $item[4])"); "round(T$t1 + $item[6]*SQRT(T$t2/$item[4]), 4)" } |
		'bollow(' expression ',' number ',' number ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); my ($t1,$t2) = Finance::HostedTrader::ExpressionParser::getID("ta_sma($vals[0],$item[4])","ta_sum(POW(($vals[0]) - ta_sma($vals[0], $item[4]), 2), $item[4])"); "round(T$t1 - $item[6]*SQRT(T$t2/$item[4]), 4)" } |
		'trend(' expression ',' number ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); my ($t1,$t2) = Finance::HostedTrader::ExpressionParser::getID("ta_sma($vals[0],$item[4])","ta_sum(POW($vals[0] - ta_sma($vals[0], $item[4]), 2), $item[4])"); "round(($vals[0] - T$t1) / (SQRT(T$t2/$item[4])), 2)" } |
		'macd(' expression ',' number ',' number ',' number ')' {my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); my ($t1,$t2) = Finance::HostedTrader::ExpressionParser::getID("ta_ema($vals[0],$item[4])", "ta_ema($vals[0],$item[6])");"round(T$t1 - T$t2, 4)" } |
		'macdsig(' expression ',' number ',' number ',' number ')' {my @vals=Finance::HostedTrader::ExpressionParser::checkArgs($item[2]);"T".Finance::HostedTrader::ExpressionParser::getID("round(ta_ema(ta_ema($vals[0],$item[4]) - ta_ema($item[2],$item[6]),$item[8]),4)") } |
		'abs(' expression ')' { my @vals = Finance::HostedTrader::ExpressionParser::checkArgs($item[2]); "T".Finance::HostedTrader::ExpressionParser::getID("round(abs($vals[0]), 4)") }
};

    my $parser    = Parse::RecDescent->new($grammar);

    my $self = {
        '_parser' => $parser,
        '_ds'       => ( $ds ? $ds : Finance::HostedTrader::Datasource->new() ),
        '_cache'    => {}, # caches parsing of expressions
        '_result_cache' => {}, # caches actual indicator values
    };

    return bless( $self, $class );
}

sub getIndicatorData {
    my ( $self, $args ) = @_;

    my @good_args = qw(tf fields symbol maxLoadedItems startPeriod endPeriod numItems debug cacheResults);

    foreach my $key (keys %$args) {
        die("invalid arg in getIndicatorData: $key") unless grep { /$key/ } @good_args;
    }

    #Handle arguments
    my $tf_name = $args->{tf} || 'day';
    my $tf = $self->{_ds}->cfg->timeframes->getTimeframeID($tf_name);
    die( "Could not understand timeframe " . ( $tf_name ) ) if (!$tf);
    my $maxLoadedItems = $args->{maxLoadedItems};
    $maxLoadedItems = 10_000_000_000
      if ( !defined( $args->{maxLoadedItems} ) );
    my $displayEndDate   = $args->{endPeriod} || '9999-12-31';
    my $displayStartDate = $args->{startPeriod} || '0001-01-31';
    my $order_ext = 'ASC';
    my $order_int = 'DESC';
    my $itemCount = $args->{numItems} || $maxLoadedItems;
    my $expr      = $args->{fields}          || die("No fields set for indicator");
    my $symbol    = $args->{symbol}          || die("No symbol set for indicator");
    my $cacheResults = $args->{cacheResults};
    $cacheResults = 1 if (!defined($cacheResults));

    my $cache_key = "$symbol-$tf-$expr-$maxLoadedItems-$itemCount";
    my $cached_result = $self->{_result_cache}->{$cache_key};
    if ($cached_result && $cached_result->[0] eq "$displayStartDate/$displayEndDate") {
        return $cached_result->[1];
    }

    my ( $result, $select_fields );
    my $cache = $self->{_cache}->{$expr};
    if ( defined($cache) ) {
        ( $result, $select_fields ) =
          ( $cache->{result}, $cache->{select_fields} );
    }
    else {

#Reset the global variable the parser uses to store information
#TODO: This shouldn't be global, I ought to have one of these per call
#TODO: Refactor the parser bit so that it can be called independently. This will be usefull to validate expressions before running them.
        %INDICATORS = ();
        $result     = $self->{_parser}->start_indicator($expr);

#TODO: Need a more meaningfull error message describing what's wrong with the given expression
        die("Syntax error in indicator \n\n$expr\n")
          unless ( defined($result) );
        my @fields = map { "$_ AS T$INDICATORS{$_}" } keys %INDICATORS;
        $select_fields = join( ', ', @fields );
        $self->{_cache}->{$expr} =
          { 'result' => $result, 'select_fields' => $select_fields };
    }

    $select_fields = ',' . $select_fields if ($select_fields);

    my $WHERE_FILTER = "WHERE datetime <= '$displayEndDate'";
    $WHERE_FILTER .= ' AND dayofweek(datetime) <> 1' if ( $tf != 604800 );

    my $EXT_WHERE = "datetime >= '$displayStartDate'";

    my $sql = qq(
SELECT * FROM (
SELECT $result FROM (
SELECT *$select_fields
FROM (
    SELECT * FROM (
        SELECT * FROM $symbol\_$tf
        $WHERE_FILTER
        ORDER BY datetime $order_int
        LIMIT $maxLoadedItems
    ) AS T_LIMIT
    ORDER BY datetime
) AS T_INNER
) AS T_OUTER
WHERE $EXT_WHERE
ORDER BY datetime $order_int
LIMIT $itemCount
) AS DT
ORDER BY datetime $order_ext
);

    print $sql if ($args->{debug});

    my $dbh = $self->{_ds}->dbh;
    my $data = $dbh->selectall_arrayref($sql) or die($DBI::errstr);
    my $lastItemIndex = scalar(@$data) - 1;
    if ( 0 && defined($itemCount) && ( $lastItemIndex > $itemCount ) ) {
        my @slice =
          @{$data}[ $lastItemIndex - $itemCount + 1 .. $lastItemIndex ];
        return \@slice;
    }
    
    $self->{_result_cache}->{$cache_key} = [ "$displayStartDate/$displayEndDate", $data ] if ($cacheResults);
    return $data;
}

sub getSignalData {
    my ( $self, $args ) = @_;
    my $sql = $self->_getSignalSql($args);
    print $sql if ($args->{debug});

    my $dbh = $self->{_ds}->dbh;
    my $data = $dbh->selectall_arrayref($sql) or die( $DBI::errstr . $sql );
    return $data;
}

sub getSystemData {
    my ( $self, $a ) = @_;

    my %args = %{ $a };

    $args{expr} = delete $args{enter};
    my $exitSignal = delete $args{exit};
    $args{fields} = "'ENTRY' AS Action, datetime, close";
    my $sql_entry = $self->_getSignalSql(\%args);
    $args{expr} = $exitSignal;
    $args{fields} = "'EXIT' AS Action, datetime, close";
    my $sql_exit  = $self->_getSignalSql(\%args);


    my $sql = $sql_entry . ' UNION ALL ' . $sql_exit . ' ORDER BY datetime';
    print $sql if ($args{debug});

    my $dbh = $self->{_ds}->dbh;
    my $data = $dbh->selectall_arrayref($sql) or die( $DBI::errstr . $sql );
    return $data;
}

sub _getSignalSql {
my ($self, $args) = @_;

    my @good_args = qw(tf expr symbol maxLoadedItems startPeriod endPeriod numItems fields debug noOrderBy);

    foreach my $key (keys %$args) {
        die("invalid arg in _getSignalSql: $key") unless grep { /$key/ } @good_args;
    }

    my $tf_name = $args->{tf} || 'day';
    my $tf = $self->{_ds}->cfg->timeframes->getTimeframeID($tf_name);
    die( "Could not understand timeframe " . ( $tf_name ) ) if (!$tf);
    my $expr   = $args->{expr}   || die("No expression set for signal");
    my $symbol = $args->{symbol} || die("No symbol set");
    my $maxLoadedItems = $args->{maxLoadedItems};
    my $startPeriod = $args->{startPeriod} || '0001-01-01 00:00:00';
    my $endPeriod = $args->{endPeriod} || '9999-12-31 23:59:59';
    my $fields = $args->{fields} || 'datetime';
    my $nbItems = $args->{numItems} || 10_000_000_000;

    $maxLoadedItems = 10_000_000_000
      if ( !defined( $args->{maxLoadedItems} ));

    %INDICATORS = ();
    my $result = $self->{_parser}->start_signal( $args->{expr} );
    die("Syntax error in signal \n\n$expr\n") unless ( defined($result) );

    my @fields = map { "$_ AS T$INDICATORS{$_}" } keys %INDICATORS;
    my $select_fields = join( ', ', @fields );
    $select_fields = ',' . $select_fields if ($select_fields);

    my $WHERE_FILTER = " WHERE datetime <= '$endPeriod'";
    $WHERE_FILTER .= ' AND dayofweek(datetime) <> 1' if ( $tf != 604800 );
    my $ORDERBY_CLAUSE='';
       $ORDERBY_CLAUSE='ORDER BY datetime' if (!$args->{noOrderBy});

    my $sql = qq(
SELECT $fields FROM (
SELECT $fields FROM (
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
WHERE ( $result ) AND datetime >= '$startPeriod' AND datetime <='$endPeriod'
ORDER BY datetime DESC
LIMIT $nbItems
) AS DT
$ORDERBY_CLAUSE
);

return $sql;

}


#Check wether a given signal occurred in a given period of time
sub checkSignal {
    my ( $self, $args ) = @_;

    my @good_args = qw( expr symbol tf maxLoadedItems debug period simulatedNowValue);

    foreach my $key (keys %$args) {
        die("invalid arg in checkSignal: $key") unless grep { /$key/ } @good_args;
    }

    my $expr = $args->{expr} || die("expr argument missing in checkSignal");
    my $symbol = $args->{symbol} || die("symbol argument missing in checkSignal");
    my $timeframe = $args->{tf} || die("timeframe argument missing in checkSignal");
    my $maxLoadedItems = $args->{maxLoadedItems} || -1;
    my $debug = $args->{debug} || 0;
    my $period = $args->{period} || 3600;
    my $nowValue = $args->{simulatedNowValue} || 'now';

    my $startPeriod = UnixDate(DateCalc($nowValue, '- '.$period."seconds"), '%Y-%m-%d %H:%M:%S');
    my $endPeriod = UnixDate($nowValue, '%Y-%m-%d %H:%M:%S');
    my $data = $self->getSignalData(
        {
            'expr'            => $expr,
            'symbol'          => $symbol,
            'tf'              => $timeframe,
            'maxLoadedItems'  => $maxLoadedItems,
            'startPeriod'     => $startPeriod,
            'endPeriod'       => $endPeriod,
            'numItems'        => 1,
            'debug'           => $debug,
        }
    );

    return $data->[0] if defined($data);
}
1;
