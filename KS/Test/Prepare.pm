# *********************************************************************
package KS::Test::Prepare;
# *********************************************************************

use strict;
use warnings;
use utf8;

use KS::Accessor (
	tt     => 'tt',
	dbh    => 'dbh',
	mreg   => 'mreg:rw',
	logger => 'logger',
);

use PTF::Request;

use Template;


sub new {
	my $class = shift;
	my %p     = @_;

	my $self = bless {
		project_dir => $p{project_dir},
		mreg        => $p{mreg},
		logger      => $p{logger},
		dbh         => $p{dbh},
		tt          => undef,
	}, $class;

	$self->{tt} = Template->new(
		INCLUDE_PATH => $p{project_dir},
		ABSOLUTE =>  0,
		ENCODING => 'utf8',
		RELATIVE =>  0,
	) or die $Template::ERROR;

	# available to use a tt-variable started with "_" and "."
	$Template::Stash::PRIVATE = undef;

	return $self;
}



## @method obj ptf_request(string file_path, hash p)
# prepare PTF request object
# @param \c file_path - \c string path to the template file
#                       if file_path is a multiline string 
#                       it will treated as template, not a file path
# @param \c p params  - \c key-value pairs for the template variables
# @return \c obj PTF::Request
sub ptf_request {
	my ($self, $fpath, %p) = @_;

	# if we got multiline in the fpath then it is a template string actually
	my $tmpl = $fpath =~ /\n/m ? $fpath : KS::Util::read_file($fpath);
	my $content = $self->{tt}->context->process(\$tmpl, \%p);
	my $req = PTF::Request->new->parse($content);

	return $req;
}



## mock_ptf_response(hash p)
# prepare mock response for external interfaces
# param "p" hash with keys:
#    _skip    - arrayref list of patterns those shouldn't be mocked
#    pattern  - string pattern for request string for mock 
#               the value is a string or arrayref of strings for path to the mock response file
# return obj configurated mock request (PTF::Request)
# retval false for error
sub mock_ptf_response {
	my $self = shift;
	my %p    = @_;

	require "Mock/PTF/Request.pm";
	require "Mock/PTF/Metaregistry.pm";

	my $mock_request = PTF::Request->new;
	$mock_request->configure( \%p );

	return $mock_request;
}




## bool create_domain(hash p)
# create domain in the system
# param "p" hash with keys:
#    name     - string domain name
# retval true for success
# retval false for error
sub create_domain {
	my ($self, %p) = @_;

	my $user            = $p{user} || 'messe';
	my $period          = $p{period} || 1;
	my $period_type     = $p{period_type} || 'YEAR';
	my $registryaccount = $p{'registryaccount'} || 'TEST/keys';
	my $auth            = $p{'auth'} || 'xxxx-test-auth-xxx';

	my $sth = $self->dbh->prepare(qq{
		INSERT INTO domains 
		(
			domain,
			created_by,
			created_date,
			updated_by,
			updated_date,
			registrar,
			registration_expiration_date,
			paid_until,
			zone,
			auth_code,
			registryaccount
		) 
		VALUES 
		(
			?,
			?,
			now(),
			?,
			now(),
			?,
			DATE_ADD(now(), INTERVAL $period $period_type),
			DATE_ADD(now(), INTERVAL $period $period_type),
			?,
			?,
			?
		)
	});

	my $zone = METARegistry::getZone( $p{name} );
	$sth->execute( $p{name}, $user, $user, $user, $zone, $auth, $registryaccount )
		or die $sth->errstr;

	# 	my $ret = $sth->execute($domain,$user,$user,$user,$zone,$auth,$registryaccount);

	# KS::Util::debug([$p{name},$user,$user,$user,$zone,$auth,$registryaccount]);
	# KS::Util::debug(qq{
	# 	INSERT INTO domains 
	# 	(
	# 		domain,
	# 		created_by,
	# 		created_date,
	# 		updated_by,
	# 		updated_date,
	# 		registrar,
	# 		registration_expiration_date,
	# 		paid_until,
	# 		zone,
	# 		auth_code,
	# 		registryaccount
	# 	) 
	# 	VALUES 
	# 	(
	# 		?,
	# 		?,
	# 		now(),
	# 		?,
	# 		now(),
	# 		?,
	# 		DATE_ADD(now(), INTERVAL $period $period_type),
	# 		DATE_ADD(now(), INTERVAL $period $period_type),
	# 		?,
	# 		?,
	# 		?
	# 	)
	# });


	# 		"INSERT INTO domains (
	# 			domain, created_by, created_date, updated_by, updated_date, registrar, ".
	# 			"registration_expiration_date, paid_until, zone, auth_code, registryaccount) ".
	# 		"VALUES (?,?,now(),?,now(),?,DATE_ADD(now(), INTERVAL $period $period_type),".
	# 			"DATE_ADD(now(), INTERVAL $period $period_type),?,?,?);");
	# 	my $ret = $sth->execute($domain,$user,$user,$user,$zone,$auth,$registryaccount);

	# $self->dbh->prepare();


	return $p{name};
}



1;



