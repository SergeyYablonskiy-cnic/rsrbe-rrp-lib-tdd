# *********************************************************************
package KS::Test::GarbageCollector;
# *********************************************************************

use strict;
use warnings;
use utf8;


use KS::Accessor (
	dbh         => 'dbh',
	list        => 'list',
	start_point => 'start_point',
	logger      => 'logger',
);



sub new {
	my $class = shift;
	my %p = @_;

	my $self = bless {
		dbh         => $p{dbh},
		list        => [],
		start_point => {},
		logger      => $p{logger},
	}, $class;

	# my ($max_id) = $self->dbh->selectrow_array( ' SELECT MAX(job_index) FROM jobs ' );
	# $self->{start_point}{jobs} = $max_id;
	# KS::Util::debug($self->{start_point});

	return $self;
}


## bool add(string type, string id)
# add element to the garbage collector
# arg "type" - string element type (domain/contact/etc)
# arg "id"   - string uniq element id, usually primary key in the table
# retval int "id" when element was success created
# retval true for success
# retval false for error
sub add {
	my ($self, $type, $id) = @_;

	# object should be deleted in reverse added order in case avoid conflicts
	unshift @{$self->list}, { $type => $id };
	$self->logger->debug('GC an element added: '. $type .' => ' . $id );
	return 1;
}



## bool cleanup(string type, string id)
# delete element from system/database/etc
# arg "type" - string element type (domain/contact/etc)
# arg "id"   - string uniq element id, usually primary key in the table
# retval int "id" when element was success created
# retval true for success
# retval false for error
sub cleanup {
	my ($self, $type, $id) = @_;

	$self->logger->debug('GC clean: '. $type .' => ' . $id );
	my $method = '_delete_'.$type;
	$self->$method($id);
}



sub _delete_domain {
	my ($self, $domain) = @_;

	$self->dbh->do( 'DELETE FROM domainContacts WHERE domain = ?',    undef, $domain );
	$self->dbh->do( 'DELETE FROM domainStatus WHERE domain = ?',      undef, $domain );
	$self->dbh->do( 'DELETE FROM domainExtensions WHERE domain = ?',  undef, $domain );
	$self->dbh->do( 'DELETE FROM domainNameservers WHERE domain = ?', undef, $domain );
	$self->dbh->do( 'DELETE FROM transfers WHERE domain = ?',         undef, $domain );
	$self->dbh->do( 'DELETE FROM jobqueue WHERE object_id = ?',       undef, $domain );
	$self->dbh->do( 'DELETE FROM commandLog WHERE object_id = ?',     undef, $domain );
	$self->dbh->do( 'DELETE FROM domains WHERE domain = ?',           undef, $domain );

	# $self->dbh->do( 'DELETE FROM jobs WHERE script like ? and job_index > ?',   undef, '%'.$domain.'%', $self->start_point->{jobs} );
	$self->dbh->do( 'DELETE FROM jobs WHERE script LIKE ?',   undef, '%'.$domain.'%' );
	$self->logger->debug('GC domain "'.$domain.'" has been deleted' );

	return 1;
}



sub DESTROY {
	my $self = shift;

	# KS::Util::debug('DESTROY', $self->list);
	for my $item ( @{$self->list} ) {
		my ($type, $id) = each %$item;
		$self->cleanup($type, $id );
	}

	return 1;
}






1;



