package Finance::HostedTrader::Config;

# ABSTRACT: Finance::HostedTrader::Config - Configuration for the Finance::HostedTrader platform

=head1 SYNOPSIS

    use Finance::HostedTrader::Config;
    my $obj = $Finance::HostedTrader::Config->new(); #Builds from merged config file(s) (eg: /etc/fx.yml ~/.fx.yml fx.yml)

    ... OR ...

    my $merge_files = Finance::HostedTrader::Config->new( #Builds from specified config files
		'files' => [
			'cfg1.yml',
			'cfg2.yml', ]);

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

=cut

use strict;
use warnings;
use Config::Any;
use Data::Dumper;
use Hash::Merge;
use Moose;

use Finance::HostedTrader::Config::DB;
use Finance::HostedTrader::Config::Symbols;
use Finance::HostedTrader::Config::Timeframes;

BEGIN {
               Hash::Merge::specify_behavior(
                   {
                               'SCALAR' => {
                                       'SCALAR' => sub { $_[0] },
                                       'ARRAY'  => sub { $_[0] },
                                       'HASH'   => sub { $_[0] },
                               },
                               'ARRAY' => {
                                       'SCALAR' => sub { $_[0] },
                                       'ARRAY'  => sub { $_[0] },
                                       'HASH'   => sub { $_[0] },
                               },
                               'HASH' => {
                                       'SCALAR' => sub { $_[0] },
                                       'ARRAY'  => sub { $_[0] },
                                       'HASH'   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) },
                               },
                       },
                       'custom_merge',
               );
}


=attr C<db>
<L><Finance::HostedTrader::Config::DB> object containing db config information
=cut
has db => (
    is       => 'ro',
    isa      => 'Finance::HostedTrader::Config::DB',
    required => 1,
);

=attr C<symbols>
<L><Finance::HostedTrader::Config::Symbols> object containing available symbols
=cut
has symbols => (
    is       => 'ro',
    isa      => 'Finance::HostedTrader::Config::Symbols',
    required => 1,
);

=attr C<timeframes>
<L><Finance::HostedTrader::Config::Timeframes> object containing available timeframes
=cut
has timeframes => (
    is       => 'ro',
    isa      => 'Finance::HostedTrader::Config::Timeframes',
    required => 1,
);

=method C<BUILDARGS>

See SYNOPSIS for available options.

=cut
around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my @files   = ( "/etc/fx.yml", "$ENV{HOME}/.fx.yml", "./fx.yml", @_ );

    if ( scalar(@_) > 1 ) {
	if ( $_[0] eq 'files' ) {
		@files = @{$_[1]};
	} else {
# Direct constructor without reading any configuration file 
         return $class->$orig(@_);
	}
    }



    my $cfg_all = Config::Any->load_files(
        { files => \@files, use_ext => 1, flatten_to_hash => 1 } );
    my $cfg = {};

    die("No config files found.\nCreate one of these to continue:\n\t" . join("\n\t", @files) . "\n") if scalar(keys(%{$cfg_all})) == 0;

	my $merge = Hash::Merge->new('custom_merge');

    foreach my $file (@files) {
        next unless ( $cfg_all->{$file} );
	my $new_cfg = $merge->merge($cfg_all->{$file}, $cfg);
	$cfg=$new_cfg;
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

=head1 SEE ALSO

L<Finance::HostedTrader::Datasource>,L<Finance::HostedTrader::Config>,L<Finance::HostedTrader::Config::DB>,L<Finance::HostedTrader::Config::Timeframes>,L<Finance::HostedTrader::Symbols>

=cut
