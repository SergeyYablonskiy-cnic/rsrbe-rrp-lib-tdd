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

use KS::Accessor (
	prepare     => 'prepare',
	project_dir => 'project_dir',
);



sub new {
	my $class = shift;
	my %p = @_;

	my $self = bless {
		project_dir => $PROJECT_DIR,
		prepare     => KS::Test::Prepare->new( project_dir => $PROJECT_DIR ),
	}, $class;

	return $self;
}



sub log_request {
	my ($self, $req, $res) = @_;

	KS::Util::debug("\n",
		KS::Util::format_date(time, 'YYYY-MM-DD hh:mm:ss') . ' ' . $req->commandname,
		'----------- START --------------',
		$req->toString, $res->toString,
		'------------ END ----------------'
	);
	return;
}



1;