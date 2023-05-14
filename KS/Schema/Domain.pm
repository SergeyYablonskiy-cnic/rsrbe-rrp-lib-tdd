use utf8;
package KS::Schema::Domain;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

KS::Schema::Domain

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<domains>

=cut

__PACKAGE__->table("domains");

=head1 ACCESSORS

=head2 domain

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 created_by

  data_type: 'varchar'
  default_value: 'keysys'
  is_nullable: 0
  size: 128

=head2 created_date

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 updated_by

  data_type: 'varchar'
  default_value: 'keysys'
  is_nullable: 0
  size: 128

=head2 updated_date

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 registrar

  data_type: 'varchar'
  default_value: 'keysys'
  is_nullable: 0
  size: 128

=head2 registration_expiration_date

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 zone

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 40

=head2 registrar_transfer_date

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 domain_index

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 auth_code

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 needs_update

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 extension

  data_type: 'varchar'
  is_nullable: 0
  size: 2048

=head2 paid_until

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 registryaccount

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 renewalmode

  data_type: 'enum'
  default_value: 'DEFAULT'
  extra: {list => ["DEFAULT","AUTORENEW","AUTOEXPIRE","AUTODELETE","RENEWONCE","AUTORENEWMONTHLY","AUTORENEWQUARTERLY","SAFEAUTORENEW","EXPIREAUCTION","RENEWONCETHENAUTODELETE","RENEWONCETHENAUTOEXPIRE"]}
  is_nullable: 0

=head2 transfermode

  data_type: 'enum'
  default_value: 'DEFAULT'
  extra: {list => ["DEFAULT","AUTOAPPROVE","AUTODENY"]}
  is_nullable: 0

=head2 renewaldate

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  default_value: '0000-00-00 00:00:00'
  is_nullable: 0

=head2 domain_idn

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "domain",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "created_by",
  {
    data_type => "varchar",
    default_value => "keysys",
    is_nullable => 0,
    size => 128,
  },
  "created_date",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "updated_by",
  {
    data_type => "varchar",
    default_value => "keysys",
    is_nullable => 0,
    size => 128,
  },
  "updated_date",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "registrar",
  {
    data_type => "varchar",
    default_value => "keysys",
    is_nullable => 0,
    size => 128,
  },
  "registration_expiration_date",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "zone",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 40 },
  "registrar_transfer_date",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "domain_index",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "auth_code",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "needs_update",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "extension",
  { data_type => "varchar", is_nullable => 0, size => 2048 },
  "paid_until",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "registryaccount",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "renewalmode",
  {
    data_type => "enum",
    default_value => "DEFAULT",
    extra => {
      list => [
        "DEFAULT",
        "AUTORENEW",
        "AUTOEXPIRE",
        "AUTODELETE",
        "RENEWONCE",
        "AUTORENEWMONTHLY",
        "AUTORENEWQUARTERLY",
        "SAFEAUTORENEW",
        "EXPIREAUCTION",
        "RENEWONCETHENAUTODELETE",
        "RENEWONCETHENAUTOEXPIRE",
      ],
    },
    is_nullable => 0,
  },
  "transfermode",
  {
    data_type => "enum",
    default_value => "DEFAULT",
    extra => { list => ["DEFAULT", "AUTOAPPROVE", "AUTODENY"] },
    is_nullable => 0,
  },
  "renewaldate",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
  },
  "domain_idn",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</domain>

=back

=cut

__PACKAGE__->set_primary_key("domain");

=head1 UNIQUE CONSTRAINTS

=head2 C<domain_index>

=over 4

=item * L</domain_index>

=back

=cut

__PACKAGE__->add_unique_constraint("domain_index", ["domain_index"]);


# Created by DBIx::Class::Schema::Loader v0.07048 @ 2023-03-31 22:58:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9k2WlD1KdSJ6LsfO4IwBLg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
