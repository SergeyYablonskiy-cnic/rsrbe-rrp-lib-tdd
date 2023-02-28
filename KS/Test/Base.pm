# *********************************************************************
package KS::Test::Base;
# *********************************************************************

use strict;
use warnings;

use FindBin('$Bin');

our $root_dir;
BEGIN {
	$root_dir = (split '/opt/metaregistry5/', $Bin)[0] . '/opt';
}

use lib (
	$root_dir . '/lib',
	$root_dir . '/lib-mreg',
	$root_dir . '/metaregistry5',
	$root_dir . '/metaregistry5/Lib',
	$root_dir . '/metaregistry5/tests/lib'
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

	my $project_dir = $root_dir . '/metaregistry5';

	my $self = bless {
		project_dir => $project_dir,
		prepare     => KS::Test::Prepare->new( project_dir => $project_dir ),
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