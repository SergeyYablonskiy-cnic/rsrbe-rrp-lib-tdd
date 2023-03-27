# *********************************************************************
package KS::Test::Prepare;
# *********************************************************************

use strict;
use warnings;
use utf8;

use KS::Accessor (
	tt     => 'tt',
	logger => 'logger',
);

use PTF::Request;

use Template;


sub new {
	my $class = shift;
	my %p     = @_;
	my $project_dir = shift;

	my $self = bless {
		project_dir => $p{project_dir},
		logger      => $p{logger},
		tt          => undef,
	}, $class;

	$self->{tt} = Template->new(
		INCLUDE_PATH => $project_dir,
		ABSOLUTE =>  0,
		ENCODING => 'utf8',
		RELATIVE =>  0,
	) or die $Template::ERROR;

	return $self;
}



## @method obj ptf_request(string file_path, hash p)
# prepare PTF request object
# @param \c file_path - \c string path to the template file
# @param \c p params  - \c key-value pairs for the template variables
# @return \c obj PTF::Request
sub ptf_request {
	my ($self, $fpath, %p) = @_;

	my $tmpl = KS::Util::read_file($fpath);
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
# retval true for success
# retval false for error
sub mock_ptf_response {
	my $self = shift;
	my %p    = @_;

	require "Mock/PTF/Request.pm";
	require "Mock/PTF/Metaregistry.pm";

	my $mock_request = PTF::Request->new;
	$mock_request->configure( \%p );

	return 1;
}

1;



