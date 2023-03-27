package PTF::Request;

use strict;
use warnings;
no warnings qw(redefine);

use Time::HiRes;
use PTF::Response;


our $MOCK_CONFIG = {
	patterns => {},
	counter  => {},
};



## bool configure(hashref config)
# configure mock responses
# prepare mock response for external interfaces
# param "p" hash with keys:
#    _skip    - arrayref list of patterns those shouldn't be mocked
#    pattern  - string pattern for request string for mock 
#               the value is a string or arrayref of strings for path to the mock response file
# retval true for success
# retval false for error
sub configure {
	my $self    = shift;
	my $pattern = shift;

	$MOCK_CONFIG->{skip} = delete $pattern->{_skip} || [];
	$MOCK_CONFIG->{patterns} = $pattern;
	# KS::Util::debug( $MOCK_CONFIG );

	return 1;
}



sub logger {
	return KS::Test::Logger->get_logger;
}



## bool reset_rid(void)
# generate new request id
# return string new request id
sub reset_rid {
	$_[0]->{_rid} = ( Time::HiRes::gettimeofday =~ /(\d+\.\d{3})/ )[0];
	return $_[0]->{_rid};
}



## bool rid(void)
# return string current request id value
sub rid {
	return defined $_[0]->{_rid} ? $_[0]->{_rid} : '';
}



## obj call(void)
# mock method for PTF::Request::call
# return obj PTF::Response for success
# return false if mock response couldn't be found
sub call {
	my $self = shift;


	# generate uniq request-id
	$self->reset_rid;

	my $req_str = $self->toString;

	# Unmocked requests must redirected to the real interface
	for my $skip_pattern ( @{ $MOCK_CONFIG->{skip} } ) {
		next unless $req_str =~ /$skip_pattern/ig;
		return $self->_call_origin(@_);
	}

	KS::Test::Logger->get_logger->info(
		'Request [mocked] => '.$self->commandname .', '
		.'rid: '  . $self->rid .', '
		.'socket: ' . ( $self->option('SOCKET') || '-')
	);

	# Mocked responses
	for my $pattern ( keys %{ $MOCK_CONFIG->{patterns} } ) {

		next unless $req_str =~ /$pattern/ig;

		my $res = PTF::Response->new;
		$res->{is_mocked} = 1;

		# counter of requests
		$MOCK_CONFIG->{counter}{$pattern} = exists $MOCK_CONFIG->{counter}{$pattern}
			? $MOCK_CONFIG->{counter}{$pattern} + 1
			: 0;

		# the mock response might be binded only to the pattern 
		# or to the number of request
		my $response_tt_file = ref $MOCK_CONFIG->{patterns}{$pattern}
			? $MOCK_CONFIG->{patterns}{$pattern}[ $MOCK_CONFIG->{counter}{$pattern} ]
			: $MOCK_CONFIG->{patterns}{$pattern};

		KS::Test::Logger->get_logger->debug('Mock TLD response for the pattern "'.$pattern.'": '.$response_tt_file);

		my $response_body = KS::Util::read_file( $response_tt_file );
		$res->parse( $response_body );

		KS::Test::Logger->get_logger->request($self, $res);

		return $res;

	}

	KS::Test::Logger->get_logger->error('Can not find any suitable MOCK response for the request rid: '.$self->rid);

	return undef;
}



## obj _call_origin(list params)
# original "call" method for pass request to real interfaces
# return obj PTF::Response
sub _call_origin {
	my $self = shift;

	$self->set(@_) if @_;

	$self->reset_rid;

	KS::Test::Logger->get_logger->info(
		'Request => '.$self->commandname . ', '
		.'rid: ' . $self->rid . ', '
		.'socket: ' . ( $self->option('SOCKET') || '-') 
	);

	my $ptf = $self->option('PTF');

	if( !defined $ptf || !$ptf->isa('PTF::XClient') )
	{
		if( !PTF::XClient->can('new') )
		{
			require PTF::XClient;
		}
		$ptf = PTF::XClient->new();
	}

	$self->option(SOURCE => PTF::XClient::genSource(caller()))
		unless $self->option('SOURCE');

	my $res = $ptf->sendCommand($self);

	KS::Test::Logger->get_logger->request($self, $res);


	return $res;
}






1;

