# *********************************************************************
package KS::Test::Logger;
# *********************************************************************

use strict;
use warnings;

use Log::Log4perl;
use Log::Log4perl::Level;
use Term::ANSIColor;

use KS::Accessor (
	logger         => 'logger_event',
	logger_event   => 'logger_event',
	logger_request => 'logger_request',
);


# create aliases for the log4perl methods
{
	no strict "refs";

	for my $method ( qw( info debug warn error fatal ) ) {

		*{ $method } = sub { 
			return $_[0]->logger_event->$method( 
				( $method eq 'error' || $method eq 'fatal' )
					? colored(['bright_red '], $_[1])
					: $_[1]
			);
		};

	}

}




my $LOGGER = undef;

# singletone
sub get_logger {
	return $LOGGER;
}



sub new {
	my $class    = shift;
	my %p        = @_;

	my $self = bless {
		logfile_event   => $p{root_dir} . '/logs/event.log',
		logfile_request => $p{root_dir} . '/logs/request.log',
	}, $class;

	$LOGGER = $self;

	return $self->_init;
}



sub _init {
	my $self = shift;

	Log::Log4perl->init( {
		'log4perl.category.event'   => 'DEBUG, event',
		'log4perl.category.request' => 'DEBUG, request',

		'log4perl.appender.event'             => 'Log::Log4perl::Appender::File',
		'log4perl.appender.event.filename'    =>  $self->{logfile_event},
		'log4perl.appender.event.mode'        => 'append',
		'log4perl.appender.event.layout'      => 'PatternLayout',
		'log4perl.appender.event.layout.ConversionPattern' => '%d{yyyy-MM-dd HH:mm:ss} %P %p %m%n',

		'log4perl.appender.request'           => 'Log::Log4perl::Appender::File',
		'log4perl.appender.request.filename'  =>  $self->{logfile_request},
		'log4perl.appender.request.mode'      => 'append',
		'log4perl.appender.request.layout'    => 'PatternLayout',
		'log4perl.appender.request.layout.ConversionPattern' => '%d{yyyy-MM-dd HH:mm:ss} %m%n',
	});

	$self->{logger_event}   = Log::Log4perl->get_logger('event');
	$self->{logger_request} = Log::Log4perl->get_logger('request');

	return $self;
}



## bool set_level(string level)
# change log level for events
# arg "level" - string new level, might be one of:
#               off, fatal, error, warn, info, debug, trace, all
# retval true for success
sub set_level {
	my ($self, $level) = @_;

	my $new_level = {
			off    => $OFF,
			fatal  => $FATAL,
			error  => $ERROR,
			warn   => $WARN,
			info   => $INFO,
			debug  => $DEBUG,
			trace  => $TRACE,
			all    => $ALL,
		}->{ lc $level };

	return $self->logger_event->logcroak( colored(['bright_red'], 'Invalid log level "'.$level.'"') )
		unless $new_level;

	$self->logger->level($new_level);

	return 1;
}



## bool start_test(string message)
# print to "test.log" a filename of the new test.
sub start_test {
	my ($self, $test_name) = @_;

	my($package, $filename, $line, $sub) = caller();

	Test::Most::note($test_name);
	$self->info( colored(['green'], "***** $test_name ***** $filename:$line") );

	return 1;
}



## bool request(obj req, obj res, str rid, [str direction])
# logging request and response as string
# arg "req"       - obj PTF::Request
# arg "res"       - obj PTF::Response
# arg "rid"       - string request id, optional
# arg "direction" - string request direction, optional:
#                     in  - for input requests
#                     out - for output requests
# retval true for success
# retval false for error
sub request {
	my ($self, $req, $res, $rid, $direction) = @_;

	$direction = {in => '<=', out => '=>'}->{$direction || 'unknown'} || '?=?';

	$rid ||= $req->can('rid') ? $req->rid : '-';

	my $command = ref $req eq 'PTF::Request' ? $req->commandname : '-';

	my $req_str = ref $req eq 'PTF::Request'  ? $req->toString : ( $req || '*** empty request string ***' );
	my $res_str = ref $res eq 'PTF::Response' ? $res->toString : ( $res || '*** empty response string ***' );

	return $self->logger_request->info(
		$direction .' '. $command .' '. $rid . "\n"
		. 'Socket [' . ($res->{is_mocked} ? 'mocked' : 'unmocked') . ']:  '. ( $req->option('SOCKET') || '-' ). "\n"
		. "----------- REQUEST START -------------- \n"
		. KS::Util::trim($req_str) . "\n\n"
		. KS::Util::trim($res_str) . "\n"
		. "------------ REQUEST END ---------------- \n\n "
	);

	return 1;
}


## bool request_in(obj req, obj res, str rid)
# logging input request and response as string
# note: for details see "request" method
sub request_in {
	my ($self, $req, $res, $rid) = @_;
	return $self->request($req, $res, $rid, 'in');
}


## bool request_out(obj req, obj res, str rid)
# logging output request and response as string
# note: for details see "request" method
sub request_out {
	my ($self, $req, $res, $rid) = @_;
	return $self->request($req, $res, $rid, 'out');
}



1;

