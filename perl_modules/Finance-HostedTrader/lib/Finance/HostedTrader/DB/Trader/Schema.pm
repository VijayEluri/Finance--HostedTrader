package Finance::HostedTrader::DB::Trader::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-10-30 20:44:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4MgvxUsVmKHfojlYe7qY0w


__PACKAGE__->connection(
    'dbi:mysql:dbname=trader', 'fxhistor', undef,
    {}
);
1;
