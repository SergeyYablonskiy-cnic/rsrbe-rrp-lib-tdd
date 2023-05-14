# *********************************************************************
package KS::Test::Model;
# *********************************************************************

use strict;
use warnings;

use base qw( DBIx::Class::Schema );

# use Model::Domain;

use KS::Accessor (
	schema => 'schema',
);


# __PACKAGE__->load_classes(
# 	'KS::Schema' => [ qw( Domain ) ],
# );

# __PACKAGE__->load_classes(
# 	[ 'KS::Schema::Domain' ],
# );

# __PACKAGE__->load_classes({
# 	'KS::Schema' => ['Domains', 'Contact'],
# });


sub new {
	my $class = shift;
	my %p = @_;

	my $self = bless {
		db          => $p{db},
		logger      => $p{logger},
		schema      => undef,
	}, $class;


	$self->load_classes({
		'KS::Schema' => ['Domain', 'Contact'],
	});

	my $config = $p{db}->get_db_config('MASTER');

	# $self->{schema} = $self->connect(
	$self->{schema} = $self->connect(
		'DBI:mysql:' . 'database=' . $config->{'name'} . ';host=' . $config->{'host'},
		$config->{'user'},
		$config->{'pass'},
	) or die $!;


	return $self;
}





1;

