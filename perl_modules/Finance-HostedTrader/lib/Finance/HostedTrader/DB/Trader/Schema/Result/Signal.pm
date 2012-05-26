package Finance::HostedTrader::DB::Trader::Schema::Result::Signal;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Finance::HostedTrader::DB::Trader::Schema::Result::Signal

=cut

__PACKAGE__->table("Signals");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 direction

  data_type: 'enum'
  extra: {list => ["long","short"]}
  is_nullable: 0

=head2 description

  data_type: 'varchar'
  is_nullable: 0
  size: 250

=head2 timeframe

  data_type: 'varchar'
  is_nullable: 0
  size: 6

=head2 maxloadeditems

  data_type: 'smallint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 startdelta

  data_type: 'varchar'
  default_value: '2 days ago'
  is_nullable: 0
  size: 15

=head2 period

  data_type: 'varchar'
  is_nullable: 0
  size: 15

=head2 definition

  data_type: 'text'
  is_nullable: 0

=head2 priceindicator

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "direction",
  {
    data_type => "enum",
    extra => { list => ["long", "short"] },
    is_nullable => 0,
  },
  "description",
  { data_type => "varchar", is_nullable => 0, size => 250 },
  "timeframe",
  { data_type => "varchar", is_nullable => 0, size => 6 },
  "maxloadeditems",
  { data_type => "smallint", extra => { unsigned => 1 }, is_nullable => 0 },
  "startdelta",
  {
    data_type => "varchar",
    default_value => "2 days ago",
    is_nullable => 0,
    size => 15,
  },
  "period",
  { data_type => "varchar", is_nullable => 0, size => 15 },
  "definition",
  { data_type => "text", is_nullable => 0 },
  "priceindicator",
  { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id", "direction");

=head1 RELATIONS

=head2 signals_alerts

Type: has_many

Related object: L<Finance::HostedTrader::DB::Trader::Schema::Result::SignalAlerts>

=cut

__PACKAGE__->has_many(
  "signals_alerts",
  "Finance::HostedTrader::DB::Trader::Schema::Result::SignalAlerts",
  { "foreign.signalid" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-10-30 20:44:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:K5F7U7Ys07avbkKnibde5A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
