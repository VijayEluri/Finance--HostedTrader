package Finance::HostedTrader::Datasource;
=head1 NAME

    Finance::HostedTrader::Datasource - Database access for the HostedTrader platform

=head1 SYNOPSIS

    use Finance::HostedTrader::Datasource;
    my $db = Datasource->new();

=head1 DESCRIPTION


=head2 Methods

=over

=cut

use strict;
use warnings;
use DBI;
use Config::Any;
use Data::Dumper;

my %timeframes = (
    'tick'  => 0,
    'sec'   => 1,
    '5sec'  => 5,
    '15sec' => 15,
    '30sec' => 30,
    'min'   => 60,
    '5min'  => 300,
    '15min' => 900,
    '30min' => 1800,
    'hour'  => 3600,
    '2hour' => 7200,
    '3hour' => 10800,
    '4hour' => 14400,
    'day'   => 86400,
    '2day'  => 172800,
    'week'  => 604800
);

=item C<new>

Returns a new Finance::HostedTrader::Datasource object.

=cut
sub new {
    my $class   = shift;
    my @files   = ( "/etc/fx.yml", "$ENV{HOME}/.fx.yml", "./fx.yml" );
    my $cfg_all = Config::Any->load_files(
        { files => \@files, use_ext => 1, flatten_to_hash => 1 } );
    my $cfg = {};

    foreach my $file (@files) {
        next unless ( $cfg_all->{$file} );
        foreach my $key ( keys %{ $cfg_all->{$file} } ) {
            $cfg->{$key} = $cfg_all->{$file}->{$key};
        }
    }

    my $dbh = DBI->connect(
        'DBI:mysql:' . $cfg->{db}->{dbname} . ';host=' . $cfg->{db}->{dbhost},
        $cfg->{db}->{dbuser},
        $cfg->{db}->{dbpasswd}
    ) || die($DBI::errstr);
    bless {
        'dbh' => $dbh,
        'cfg' => $cfg,
    }, $class;
}

=item C<convertOHLCTimeSeries>

=cut
sub convertOHLCTimeSeries {
    my ( $self, $symbol, $tf_src, $tf_dst, $start_date, $end_date ) = @_;
    my ( $where_clause, $start, $end, $limit ) = ( '', '', '', -1 );
    die('Cannot convert to a smaller timeframe') if ( $tf_dst < $tf_src );

    my ( $date_select, $date_group );

    if ( $tf_dst == 300 ) {
        $date_select =
"CAST(CONCAT(year(datetime), '-', month(datetime), '-', day(datetime), ' ',  hour(datetime), ':', floor(minute(datetime) / 5) * 5, ':00') AS DATETIME)";
    }
    elsif ( $tf_dst == 900 ) {
        $date_select =
"CAST(CONCAT(year(datetime), '-', month(datetime), '-', day(datetime), ' ',  hour(datetime), ':', floor(minute(datetime) / 15) * 15, ':00') AS DATETIME)";
    }
    elsif ( $tf_dst == 1800 ) {
        $date_select =
"CAST(CONCAT(year(datetime), '-', month(datetime), '-', day(datetime), ' ',  hour(datetime), ':', floor(minute(datetime) / 30) * 30, ':00') AS DATETIME)";
    }
    elsif ( $tf_dst == 3600 ) {
        $date_select = "date_format(datetime, '%Y-%m-%d %H:00:00')";
    }
    elsif ( $tf_dst == 7200 ) {
        $date_select =
"CAST(CONCAT(year(datetime), '-', month(datetime), '-', day(datetime), ' ',  floor(hour(datetime) / 2) * 2, ':00:00') AS DATETIME)";
    }
    elsif ( $tf_dst == 10800 ) {
        $date_select =
"CAST(CONCAT(year(datetime), '-', month(datetime), '-', day(datetime), ' ',  floor(hour(datetime) / 3) * 3, ':00:00') AS DATETIME)";
    }
    elsif ( $tf_dst == 14400 ) {
        $date_select =
"CAST(CONCAT(year(datetime), '-', month(datetime), '-', day(datetime), ' ',  floor(hour(datetime) / 4) * 4, ':00:00') AS DATETIME)";
    }
    elsif ( $tf_dst == 86400 ) {
        $date_select = "date_format(datetime, '%Y-%m-%d 00:00:00')";
    }
    elsif ( $tf_dst == 604800 ) {
        $date_select =
"date_format(date_sub(datetime, interval weekday(datetime)+1 DAY), '%Y-%m-%d 00:00:00')";
        $date_group = "date_format(datetime, '%x-%v')";
    }
    else {
        die("timeframe not supported ($tf_dst)");
    }
    $date_group = $date_select unless ( defined($date_group) );

    my $sql = qq|
INSERT INTO $symbol\_$tf_dst
SELECT $date_select, SUBSTRING_INDEX(GROUP_CONCAT(CAST(open AS CHAR) ORDER BY datetime), ',', 1) as open, MIN(low) as low, MAX(high) as high, SUBSTRING_INDEX(GROUP_CONCAT(CAST(close AS CHAR) ORDER BY datetime DESC), ',', 1) as close
FROM $symbol\_$tf_src
WHERE datetime >= '$start_date' AND datetime < '$end_date'
GROUP BY $date_group
ON DUPLICATE KEY UPDATE open=values(open), low=values(low), high=values(high), close=values(close)
|;

    $self->{'dbh'}->do($sql);
}

=item C<createSynthetic>

=cut
sub createSynthetic {
    my ( $self, $synthetic, $timeframe ) = @_;

    my $symbols = $self->getNaturalSymbols;
    my $sym1    = substr( $synthetic, 0, 3 );
    my $sym2    = substr( $synthetic, 3, 3 );
    my $search1 = $sym1 . 'USD';
    my $search2 = 'USD' . $sym1;
    my @u1      = grep( /$search1|$search2/, @$symbols );

    $search1 = $sym2 . 'USD';
    $search2 = 'USD' . $sym2;
    my @u2 = grep( /$search1|$search2/, @$symbols );
    my $op;
    my ( $low, $high );
    if ( $u1[0] =~ /USD$/ && $u2[0] =~ /^USD/ ) {
        $op   = '*';
        $low  = 'low';
        $high = 'high';
    }
    elsif ( $u1[0] =~ /USD$/ && $u2[0] =~ /USD$/ ) {
        $op   = '/';
        $low  = 'high';
        $high = 'low';
    }
    elsif ( $u1[0] =~ /^USD/ && $u2[0] =~ /^USD/ ) {
        $op   = '/';
        $low  = 'high';
        $high = 'low';
        my $tmp = $u1[0];
        $u1[0] = $u2[0];
        $u2[0] = $tmp;
    }
    else {
        die("Don't know how to handle $synthetic [] synthetic pair");
    }

    my $filter = ' AND T1.datetime > DATE_SUB(NOW(), INTERVAL 2 WEEK)';

    my $sql =
"insert ignore into $synthetic\_$timeframe (select T1.datetime, round(T1.open"
      . $op
      . "T2.open,4) as open, round(T1.low"
      . $op
      . "T2.$low,4) as low, round(T1.high"
      . $op
      . "T2.$high,4) as high, round(T1.close"
      . $op
      . "T2.close,4) as close from $u1[0]\_$timeframe as T1, $u2[0]\_$timeframe as T2 WHERE T1.datetime = T2.datetime $filter)";

    $self->{dbh}->do($sql);
}

sub getNaturalSymbols {
    my $self    = shift;
    my $symbols = $self->{cfg}->{symbols}->{natural}
      || die('No symbols defined in config file');

    return $symbols;
}

sub getSyntheticSymbols {
    my $self = shift;
    my $symbols = $self->{cfg}->{symbols}->{synthetic} || [];

    return $symbols;
}

sub getAllSymbols {
    my $self = shift;

    return [ @{ $self->getNaturalSymbols }, @{ $self->getSyntheticSymbols } ];
}

sub getAllTimeframes {
    my $self = shift;

    my @sorted =
      sort { int($a) <=> int($b) }
      ( @{ $self->getNaturalTimeframes }, @{ $self->getSyntheticTimeframes } );

    return \@sorted;
}

sub getNaturalTimeframes {
    my $self       = shift;
    my $timeframes = $self->{cfg}->{timeframes}->{natural}
      || die('No symbols defined in config file');

    my @sorted = sort { int($a) <=> int($b) } @{$timeframes};

    return \@sorted;
}

sub getSyntheticTimeframes {
    my $self = shift;
    my $timeframes = $self->{cfg}->{timeframes}->{synthetic} || [];

    my @sorted = sort { int($a) <=> int($b) } @{$timeframes};

    return \@sorted;
}

sub getTimeframeName {
    my ( $self, $id ) = @_;
    grep { return $_ if $timeframes{$_} == $id } keys(%timeframes);
}

sub getTimeframeID {
    my ( $self, $name ) = @_;
    return $timeframes{$name};
}

sub DESTROY {
    my ($self) = @_;
    $self->{'dbh'}->disconnect;
}

1;

=back

=head1 LICENSE

This file is licensed under the MIT X11 License:

This is released under the MIT license. See L<http://www.opensource.org/licenses/mit-license.php>.

=head1 AUTHOR

Joao Costa - L<http://zonalivre.org/>

=head1 SEE ALSO

L<Finance::HostedTrader::Config>

=cut
