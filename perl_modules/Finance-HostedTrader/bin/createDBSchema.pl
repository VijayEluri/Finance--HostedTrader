#!/usr/bin/perl
package Finance::HostedTrader;
# ABSTRACT: Outputs SQL suitable to create db, mysql users and tables to store symbol historical data in various timeframes

=head1 SYNOPSIS

    createDBSchema.pl [--timeframes=tfs] [--help] [--symbols=s]

=head1 DESCRIPTION

=head2 OPTIONS

=over 12

=item C<--tableType=s>

A valid mysql table type. Defaults to MYISAM.

=item C<--timeframes=tfs>

A comma separated list of timeframe ids to generate SQL for.
If not supplied, defaults all timeframes (natural and synthetic) defined in the config file.

=item C<--symbols=s>

Comma separated list of symbols to generate SQL for.
If not supplied, defaults all symbols (natural and synthetic) defined in the config file.

=item C<--help>

Display usage information.

=back



=head1 LICENSE

This is released under the MIT license. See L<http://www.opensource.org/licenses/mit-license.php>.

=head1 AUTHOR

Joao Costa - L<http://zonalivre.org/>

=head1 SEE ALSO

L<Finance::HostedTrader::Config>

=cut

use strict;
use warnings;
use Getopt::Long;
use Finance::HostedTrader::Config;
use Pod::Usage;

my ( $symbols_txt, $tfs_txt, $help );
my ($table_type) = ('MYISAM');
my $cfg = Finance::HostedTrader::Config->new();

my $result = GetOptions( "symbols=s", \$symbols_txt, "timeframes=s", \$tfs_txt, "tableType=s", \$table_type, "help", \$help)
  or pod2usage(1);
pod2usage(1) if ($help);

my $tfs = $cfg->timeframes->all();
$tfs = [ split( ',', $tfs_txt ) ] if ($tfs_txt);
my $symbols = $cfg->symbols->all();
$symbols = [ split( ',', $symbols_txt ) ] if ($symbols_txt);
my $dbname = $cfg->db->dbname;
my $dbuser = $cfg->db->dbuser;
my $dbpasswd = $cfg->db->dbpasswd;
my $userhost = 'localhost'; #Unlikely to be anything else

print qq{
    use $dbname;
};

foreach my $symbol (@$symbols) {
    foreach my $tf (@$tfs) {
        print qq /
DROP TABLE IF EXISTS `$symbol\_$tf`;
CREATE TABLE IF NOT EXISTS `$symbol\_$tf` (
`datetime` DATETIME NOT NULL ,
`open` DECIMAL(9,4) NOT NULL ,
`high` DECIMAL(9,4) NOT NULL ,
`low` DECIMAL(9,4) NOT NULL ,
`close` DECIMAL(9,4) NOT NULL ,
PRIMARY KEY ( `datetime` )
) ENGINE = $table_type ;
/;

    }

print "GRANT ALL ON `$dbname`.* TO `$dbuser`@`$userhost`" . ($dbpasswd ? " IDENTIFIED BY `$dbpasswd`": '') . ";\n";
}
