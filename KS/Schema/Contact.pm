use utf8;
package KS::Schema::Contact;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

KS::Schema::Contact

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

=head1 TABLE: C<contacts>

=cut

__PACKAGE__->table("contacts");

=head1 ACCESSORS

=head2 contact_index

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 prefix

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 13

=head2 suffix

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 created_by

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 created_date

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 updated_by

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 updated_date

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 registrar

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 title

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 first_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 middle_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 last_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 organization

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 street

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 street1

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 street2

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 city

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 state

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 zip

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 country

  data_type: 'char'
  is_nullable: 1
  size: 3

=head2 phone

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 fax

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 email

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 encoding_type

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 id

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 32

=head2 auth

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 auto_delete

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 validated

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 verified

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 blocklist_ranking

  data_type: 'tinyint'
  is_nullable: 1

=head2 blocklist_check_date

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "contact_index",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "prefix",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 13 },
  "suffix",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "created_by",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "created_date",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "updated_by",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "updated_date",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "registrar",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "title",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "first_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "middle_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "last_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "organization",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "street",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "street1",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "street2",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "city",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "state",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "zip",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "country",
  { data_type => "char", is_nullable => 1, size => 3 },
  "phone",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "fax",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "encoding_type",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "id",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 32 },
  "auth",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "auto_delete",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "validated",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "verified",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "blocklist_ranking",
  { data_type => "tinyint", is_nullable => 1 },
  "blocklist_check_date",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</prefix>

=item * L</suffix>

=back

=cut

__PACKAGE__->set_primary_key("prefix", "suffix");

=head1 UNIQUE CONSTRAINTS

=head2 C<id>

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->add_unique_constraint("id", ["id"]);


# Created by DBIx::Class::Schema::Loader v0.07048 @ 2023-03-31 22:58:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KcbHc9eU+ftNJXGHno4Bvw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
