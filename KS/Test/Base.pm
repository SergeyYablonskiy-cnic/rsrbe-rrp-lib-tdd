# *********************************************************************
package KS::Test::Base;
# *********************************************************************

use strict;
use warnings;

use FindBin('$Bin');

our $ROOT_DIR;
our $PROJECT_DIR;

BEGIN {
	# project can be rolled up in a home directory
	# (.../opt)(metaregistry5|tld-xxx)
	$Bin =~ m|^(.+opt)/([^/]+)|;
	$ROOT_DIR = $1;
	$PROJECT_DIR = $1 .'/'. $2;
}

use lib (
	$ROOT_DIR . '/lib',
	$ROOT_DIR . '/lib-mreg',
	$ROOT_DIR . '/metaregistry5',
	$ROOT_DIR . '/metaregistry5/Lib',
	$ROOT_DIR . '/lib-test'
);


use KS::Test::Prepare;
use KS::Util;
use KS::Test::GarbageCollector;
use KS::Test::Logger;

use KS::Accessor (
	project_dir => 'project_dir',
	root_dir    => 'root_dir',
	dbh         => 'dbh',
	prepare     => 'prepare',
	gc          => 'gc',
	mreg        => 'mreg',
	logger      => 'logger',
);



sub new {
	my $class = shift;
	my %p = @_;

	my $self = bless {
		root_dir    => $ROOT_DIR,
		project_dir => $PROJECT_DIR,
		dbh         => undef,
		prepare     => undef,
		mreg        => undef,
		gc          => undef,
		logger      => undef,
	}, $class;

	return $self->_init(%p);
}



sub _init {
	my ($self, %p) = @_;

	$self->{logger}  = KS::Test::Logger->new(root_dir => $self->root_dir);

	$self->{prepare} = KS::Test::Prepare->new( 
		project_dir => $self->project_dir,
		logger      => $self->logger 
	);

	return $self;
}



## obj load_metaregistry(hash p)
# load the metaregistry mock module
# param "p" hash with keys:
#    load_commands   - arrayref of names of load commans, any others won't be loaded
#                      that makes start metaregistry a little bit faster
# return obj METARegistry
sub load_metaregistry {
	my ($self, %p) = @_;

	require  Mock::Metaregistry;
	require  Mock::Log;

	$self->{mreg} =  METARegistry->new(
		project_dir   => $self->project_dir,
		load_commands => $p{load_commands} || [],
	);

	$self->{dbh} = $self->mreg->{DBH};

	$self->{gc}  = KS::Test::GarbageCollector->new(
		dbh    => $self->dbh,
		logger => $self->logger,
	);

	return $self->mreg;
}



## bool exec_script(string path)
# execute script
# arg "path" - string path to the script, might be relative or absolute
# arg "created" - string timestamp of created element, format YYYY-MM-DD hh:mm:ss
# retval string output for stdout
sub exec_script {
	my ($self, $path) = @_;

	use IPC::Open2;

	# append root dir only for relative path
	$path = $self->root_dir . '/' . $path
		unless $path =~ m|^/|; 

	my ($in, $out);

	my $pid = open2($out, $in, $path);
	waitpid($pid,0);

	local $/ = undef;
	my $response = <$out>;

	# todo: logging to the file
	# $self->logger->log_script_output(script => $path, res => $response);
	$self->logger->info('Execute script: ' . $path .'; output: '.$response );

	return $response;
}




## bool log_request(obj req, obj res)
# logging request and response as string
# arg "req" - obj PTF::Request
# arg "res" - obj PTF::Response
# retval true for success
# retval false for error
sub log_request {
	return shift->logger->request(@_);
}



1;

