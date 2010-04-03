package Finance::HostedTrader::Config;
=head1 NAME

    Finance::HostedTrader::Config - Configuration for the Finance::HostedTrader platform

=head1 SYNOPSIS

    use Finance::HostedTrader::Config;
    my $obj = $Finance::HostedTrader::Config->new(); #Builds from config file(s) (eg: /etc/fx.yml ~/.fx.yml fx.yml)

    ... OR ...

    use Finance::HostedTrader::Config::DB;
    use Finance::HostedTrader::Config::Symbols;
    use Finance::HostedTrader::Config::Timeframes;

    my $db = Finance::HostedTrader::Config::DB->new(
		'dbhost' => 'dbhost',
		'dbname' => 'dbname',
		'dbuser' => 'dbuser',
		'dbpasswd'=> 'dbpasswd',
	);

    my $timeframes = Finance::HostedTrader::Config::Timeframes->new(
		'natural' => [ qw (300 60) ], #Make sure timeframes are unordered to test if the module returns them ordered
	);

    my $symbols = Finance::HostedTrader::Config::Symbols->new(
		'natural' => [ qw (AUDUSD USDJPY) ],
	);

    $obj = Finance::HostedTrader::Config->new( 'db' => $db, 'symbols' => $symbols, 'timeframes' => $timeframes );

=head1 DESCRIPTION


=head2 METHODS

=over 12

=cut

use strict;
use warnings;
use Config::Any;
use Data::Dumper;

use Finance::HostedTrader::Config::DB;
use Finance::HostedTrader::Config::Symbols;
use Finance::HostedTrader::Config::Timeframes;
use Moose;

=item C<db>
<L><Finance::HostedTrader::Config::DB> object containing db config information
=cut
has db => (
    is       => 'ro',
    isa      => 'Finance::HostedTrader::Config::DB',
    required => 1,
);

=item C<symbols>
<L><Finance::HostedTrader::Config::Symbols> object containing available symbols
=cut
has symbols => (
    is       => 'ro',
    isa      => 'Finance::HostedTrader::Config::Symbols',
    required => 1,
);

=item C<timeframes>
<L><Finance::HostedTrader::Config::Timeframes> object containing available timeframes
=cut
has timeframes => (
    is       => 'ro',
    isa      => 'Finance::HostedTrader::Config::Timeframes',
    required => 1,
);

=item C<new>

Constructor. See SYNOPSIS for available options.

=cut
around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    if ( scalar(@_) > 1 || ref $_[0] ) {
# Direct constructor without reading any configuration file 
         return $class->$orig(@_);
    }


    my @files   = ( "/etc/fx.yml", "$ENV{HOME}/.fx.yml", "./fx.yml", @_ );

    my $cfg_all = Config::Any->load_files(
        { files => \@files, use_ext => 1, flatten_to_hash => 1 } );
    my $cfg = {};

    foreach my $file (@files) {
        next unless ( $cfg_all->{$file} );
        foreach my $key ( keys %{ $cfg_all->{$file} } ) {
            $cfg->{$key} = $cfg_all->{$file}->{$key};
        }
    }

    my $class_args = {
        'db' => Finance::HostedTrader::Config::DB->new($cfg->{db}),
	'symbols' => Finance::HostedTrader::Config::Symbols->new($cfg->{symbols}),
	'timeframes' => Finance::HostedTrader::Config::Timeframes->new($cfg->{timeframes}),
    };

    return $class->$orig($class_args);
};

__PACKAGE__->meta->make_immutable;
1;

=back


=head1 LICENSE

This is released under the MIT license. See L<http://www.opensource.org/licenses/mit-license.php>.

=head1 AUTHOR

Joao Costa - L<http://zonalivre.org/>

=head1 SEE ALSO

L<Finance::HostedTrader::Datasource>,L<Finance::HostedTrader::Config>,L<Finance::HostedTrader::Config::DB>,L<Finance::HostedTrader::Config::Timeframes>,L<Finance::HostedTrader::Symbols>

=cut
