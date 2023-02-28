# *********************************************************************
package KS::Test::Prepare;
# *********************************************************************

use strict;
use warnings;
use utf8;

use KS::Accessor (tt => 'tt');

use PTF::Request;

use Template;


sub new {
	my $class = shift;
	my $project_dir = shift;

	my $self = bless {
		project_dir => $project_dir,
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
# @param \c p params  - \c a key-value pairs for template variables
# @return \c obj PTF::Request
sub ptf_request {
	my ($self, $fpath, %p) = @_;

	my $tmpl = KS::Util::read_file($fpath);
	my $content = $self->{tt}->context->process(\$tmpl, \%p);
	my $req = PTF::Request->new->parse($content);

	return $req;
}

1;



