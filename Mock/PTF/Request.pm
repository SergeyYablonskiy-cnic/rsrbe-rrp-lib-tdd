package PTF::Request;

use strict;
use warnings;
no warnings qw(redefine);

use Time::HiRes;
use PTF::Response;


our $MOCK_CONFIG = {
	patterns => {},
	counter  => {},
	trace    => {},
};



## bool configure(hash config)
# configure responses, prepare mock for external interfaces
# param "p" hash with keys:
#    _skip    - arrayref list of patterns those shouldn't be mocked
#    _socket  - string socket string we would like to use for all external requests
#    pattern  - string pattern for request string for mock 
#               the value is a string or arrayref of strings for path to the mock response file
# retval true for success
# retval false for error
sub configure {
	my $self    = shift;
	my %pattern = @_;

	$MOCK_CONFIG->{skip}     = delete $pattern{_skip} || [];
	$MOCK_CONFIG->{socket}   = delete $pattern{_socket} || '';
	$MOCK_CONFIG->{patterns} = \%pattern;
	# KS::Util::debug( $MOCK_CONFIG );

	return 1;
}



sub logger {
	return KS::Test::Logger->get_logger;
}



## bool add_trace(list commands)
# print to the debug.log call trace for command
# param "commans"  - list of commands for trace
sub add_trace {
	my $self = shift;
	map { $MOCK_CONFIG->{trace}{ lc $_ } = 1 } @_;
	return 1;
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



## bool _is_socket(str value)
# return TRUE if value is a socket string like 'mregd+udp://whois:whois0@10.253.15.3:6842'
sub _is_socket {
	return $_[1] =~ m|^.+://.+:.+$|;
}



## obj call(void)
# mock method for PTF::Request::call
# return obj PTF::Response for success
# return false if mock response couldn't be found
sub call {
	my $self = shift;

	# print a call trace for requests if needed
	KS::Util::debug_trace($self->commandname)
		if $MOCK_CONFIG->{trace}{ lc $self->commandname };

	# generate uniq request-id
	$self->reset_rid;

	my $req_str = $self->toString;

	# Unmocked requests must redirected to the real interface
	for my $pass_pattern ( @{ $MOCK_CONFIG->{skip} } )
	{
		return $self->_call_origin(@_)
			if ($pass_pattern  eq '*' 
				or $pass_pattern eq 'all'
				or $req_str =~ /$pass_pattern/ig
			);
	}


	# Mocked responses
	for my $pattern ( keys %{ $MOCK_CONFIG->{patterns} } )
	{
		next unless $req_str =~ /$pattern/ig;

		my $res = PTF::Response->new;
		$res->{is_mocked} = 1;

		# counter of requests
		$MOCK_CONFIG->{counter}{$pattern} = exists $MOCK_CONFIG->{counter}{$pattern}
			? $MOCK_CONFIG->{counter}{$pattern} + 1
			: 0;

		# the mock response might be binded only to the pattern
		# or to the number of request
		my $value = ref $MOCK_CONFIG->{patterns}{$pattern}
			? $MOCK_CONFIG->{patterns}{$pattern}[ $MOCK_CONFIG->{counter}{$pattern} ]
			: $MOCK_CONFIG->{patterns}{$pattern};

		# the value might be a socket string that we would like to use for this particular request
		if ( $self->_is_socket($value) ) {
			return $self->_call_origin( '-SOCKET' => $value, @_ );
		}

		my $response_tt_file = $value;

		$self->logger->info(
			'Request [mocked] => '.$self->commandname .', '
			.'rid: '  . $self->rid .', '
			.'socket: ' . ( $self->option('SOCKET') || '-')
		);

		$self->logger->debug('Mock TLD response for the pattern "'.$pattern.'": '.$response_tt_file);

		my $response_body = KS::Util::read_file( $response_tt_file );
		$res->parse( $response_body );

		$self->logger->info('Response [mocked] '.$self->rid.': '.$res->codeDescription);
		$self->logger->request_out($self, $res, $self->rid);

		return $res;
	}

	$self->logger->request_out($self, "[INTERNAL RESPONSE]\nERROR: can not find any suitable MOCK response", $self->rid);
	$self->logger->error('Can not find any suitable MOCK response for the request "'.$self->commandname.'" rid: '.$self->rid);

	return undef;
}



## obj _call_origin(list params)
# original "call" method for pass request to real interfaces
# return obj PTF::Response
sub _call_origin {
	my ($self, %p) = @_;

	my $use_socket = $p{'-SOCKET'} || $MOCK_CONFIG->{socket};

	if ( $use_socket ) {
		$p{'-SOCKET'} = $use_socket;
		$self->logger->debug('"'.$p{'-SOCKET'}.'" socket force usage is requested')
	}

	$self->reset_rid;

	$self->logger->info(
		'Request => ' . $self->commandname . ' '
		. $self->rid . ' '
		. ( $self->option('SOCKET') || '-')
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

	$self->logger->info('Response '.$self->rid.' '.$res->codeDescription);
	$self->logger->request_out($self, $res, $self->rid);


	return $res;
}






1;

