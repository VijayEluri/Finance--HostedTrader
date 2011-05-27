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
use Finance::HostedTrader::Config;
use Data::Dumper;
use Moose;

=item C<debug>

Optional If set to a true value, prints SQL queries to stdout.

Defaults to false.
=cut
has debug => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
    required => 0,
);

=item C<dbh>

Optional DBI handle to the MySQL datasource.

If not present, a new DBI handle is created from the settings in the config file.
=cut
has dbh => (
    is       => 'ro',
    isa      => 'DBI::db',
    builder  => '_build_dbh',
    lazy     => 1,
    required => 1,
);

sub _build_dbh {
    my $self = shift;
    my $cfg = $self->cfg;
    my $dbh = DBI->connect(
        'DBI:mysql:' . $cfg->db->dbname . ';host=' . $cfg->db->dbhost,
        $cfg->db->dbuser,
        $cfg->db->dbpasswd,
        { RaiseError => 1}
    );

    return $dbh;
}


=item C<cfg>

Returns the L<Finance::HostedTrader::Config> object associated with this datasource.

This object contains a list of available timeframes and symbols in this data source.
=cut
has cfg => (
    is       => 'ro',
    isa      => 'Finance::HostedTrader::Config',
    builder  => '_build_cfg',
    required => 1,
);

sub _build_cfg {
    return Finance::HostedTrader::Config->new();
}

=item C<new>

Returns a new Finance::HostedTrader::Datasource object.

=cut

=item C<convertOHLCTimeSeries>

=cut
sub convertOHLCTimeSeries {
    my ( $self, $symbol, $tf_src, $tf_dst, $start_date, $end_date ) = @_;
    my ( $where_clause, $start, $end, $limit ) = ( '', '', '', -1 );
    die('Cannot convert to a smaller timeframe') if ( $tf_dst < $tf_src );

    my ( $date_select, $date_group );

#TODO - date_select is duplicated with Timeframes.pm
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

    print "\n----------\n$sql\n----------\n" if ($self->debug);
    $self->dbh->do($sql);
}

=item C<createSynthetic>

=cut
sub createSynthetic {
    my ( $self, $synthetic, $timeframe ) = @_;

    my $symbols = $self->{cfg}->symbols->natural;
    my $sym1    = substr( $synthetic, 0, 3 );
    my $sym2    = substr( $synthetic, 3, 3 );
    my $search1 = $sym1 . 'USD';
    my $search2 = 'USD' . $sym1;
    my @u1      = grep( /$search1|$search2/, @$symbols );
    $u1[0] = '' if (!defined($u1[0]));

    $search1 = $sym2 . 'USD';
    $search2 = 'USD' . $sym2;
    my @u2 = grep( /$search1|$search2/, @$symbols );
    $u2[0] = '' if (!defined($u1[0]));
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
        die("Don't know how to handle $synthetic synthetic pair");
    }

    my $sql =
"insert ignore into $synthetic\_$timeframe (select T1.datetime, round(T1.open"
      . $op
      . "T2.open,4) as open, round(T1.low"
      . $op
      . "T2.$low,4) as low, round(T1.high"
      . $op
      . "T2.$high,4) as high, round(T1.close"
      . $op
      . "T2.close,4) as close from $u1[0]\_$timeframe as T1, $u2[0]\_$timeframe as T2 WHERE T1.datetime = T2.datetime)";
#AND T1.datetime > DATE_SUB(NOW(), INTERVAL 2 WEEK))
    $self->dbh->do($sql);
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
