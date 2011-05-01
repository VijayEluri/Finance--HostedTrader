package Finance::HostedTrader::DB::Trader::Schema::Result::SignalAlerts;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Finance::HostedTrader::DB::Trader::Schema::Result::SignalAlerts

=cut

__PACKAGE__->table("SignalAlerts");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 symbol

  data_type: 'varchar'
  is_nullable: 0
  size: 10

=head2 signalid

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 createdate

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0

=head2 validtill

  data_type: 'datetime'
  is_nullable: 1

=head2 detectedon

  data_type: 'datetime'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "symbol",
  { data_type => "varchar", is_nullable => 0, size => 10 },
  "signalid",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "createdate",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
  "validtill",
  { data_type => "datetime", is_nullable => 1 },
  "detectedon",
  { data_type => "datetime", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 signalid

Type: belongs_to

Related object: L<Finance::HostedTrader::DB::Trader::Schema::Result::Signal>

=cut

__PACKAGE__->belongs_to(
  "signalid",
  "Finance::HostedTrader::DB::Trader::Schema::Result::Signal",
  { id => "signalid" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2010-10-30 20:44:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Pe0SZNPTeiJ9YE+PyD9LJg

use DateTime::Format::MySQL;

__PACKAGE__->inflate_column(
    'detectedon',
    {
        inflate => sub {
            my $date = shift;
            DateTime::Format::MySQL($date);
        },
        deflate => sub {
            my $datetime=shift;
            $datetime->ymd() . " " . $datetime->hms();
        }
    }
);

__PACKAGE__->inflate_column(
    'validtill',
    {
        inflate => sub {
            my $date = shift;
            DateTime::Format::MySQL($date);
        },
        deflate => sub {
            my $datetime=shift;
            $datetime->ymd() . " " . $datetime->hms();
        }
    }
);
1;
