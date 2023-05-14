# *********************************************************************
package KS::Test::Model::Domain;
# *********************************************************************

use strict;
use warnings;

use base qw( DBIx::Class::Schema );



use KS::Accessor (

);



sub new {
	my $class = shift;
	my %p = @_;

	my $self = bless {
		db          => $p{db},
		logger      => $p{logger},
		schema      => $p{schema},
	}, $class;

	return $self;
}







1;

