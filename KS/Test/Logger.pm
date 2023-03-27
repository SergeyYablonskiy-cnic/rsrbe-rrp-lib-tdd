# *********************************************************************
package KS::Test::Logger;
# *********************************************************************

use strict;
use warnings;

use Log::Log4perl;

use KS::Accessor (
	logger         => 'logger',
	logger_request => 'logger_request',
);


# create aliases for the log4perl methods
{
	no strict "refs";
	for my $method ( qw( info debug warn error fatal ) ) {
		*{ $method } = sub { return shift->{logger}->$method(@_); };
	}
}


my $LOGGER = undef;



sub new {
	my $class    = shift;
	my %p        = @_;

	my $self = bless {
		logfile         => $p{root_dir} . '/logs/test.log',
		logfile_request => $p{root_dir} . '/logs/request.log',
		logger          => undef,
	}, $class;

	$LOGGER = $self;

	return $self->_init;
}



sub get_logger {
	return $LOGGER;
}




sub _init {
	my $self = shift;

	Log::Log4perl->init( {
		'log4perl.category.event'   => 'DEBUG, event',
		'log4perl.category.request' => 'DEBUG, request',

		'log4perl.appender.event'             => 'Log::Log4perl::Appender::File',
		'log4perl.appender.event.filename'    =>  $self->{logfile},
		'log4perl.appender.event.mode'        => 'append',
		'log4perl.appender.event.layout'      => 'PatternLayout',
		'log4perl.appender.event.layout.ConversionPattern' => '%d{yyyy-MM-dd HH:mm:ss} %P %p %m%n',

		'log4perl.appender.request'             => 'Log::Log4perl::Appender::File',
		'log4perl.appender.request.filename'    =>  $self->{logfile_request},
		'log4perl.appender.request.mode'        => 'append',
		'log4perl.appender.request.layout'      => 'PatternLayout',
		'log4perl.appender.request.layout.ConversionPattern' => '%d{yyyy-MM-dd HH:mm:ss} %p %m%n',

		# 'log4perl.appender.LOGFILE.layout.ConversionPattern' => '%d{yyyy-MM-dd HH:mm:ss} pid:%P %p %m%n',
		# 'log4perl.appender.LOGFILE.layout.ConversionPattern' => '%d{yyyy-MM-dd hh:mm:ss SSSSS} %P %p %m%n',
		# explain format: yyyy-mm-dd hh:mm:ss millisecond pid level message new_line
	});


	$self->{logger}         = Log::Log4perl->get_logger('event');
	$self->{logger_request} = Log::Log4perl->get_logger('request');

	return $self;
}


## bool start_test(string message)
# print to "test.log" a filename of the new test.
sub start_test {
	my ($self, $message) = @_;
	# return $self->info("\e[1;31m".'Start test: '.$0."\e[0m");
	return $self->info("\e[1;32m".'Start test: '.$0."\e[0m");
}



## bool request(obj req, obj res)
# logging request and response as string
# arg "req" - obj PTF::Request
# arg "res" - obj PTF::Response
# retval true for success
# retval false for error
sub request {
	my ($self, $req, $res) = @_;

	my $rid = $req->can('rid') ? ( $req->rid || '-') : '-';

	my $command = ref $req eq 'PTF::Request' ? $req->commandname : '-';

	return $self->logger_request->info(
		"Command: ". $command . '; rid: ' . $rid . "\n"
		. 'Socket [' . ($res->{is_mocked} ? 'mocked' : 'unmocked') . ']:  '. ( $req->option('SOCKET') || '-' ). "\n"
		. "----------- REQUEST START -------------- \n"
		. ( ref $req eq 'PTF::Request'  ? $req->toString : ( $req || '!empty string!' ) ) . "\n"
		. ( ref $res eq 'PTF::Response' ? $res->toString : ( $res || '!empty string!' ) ) . "\n"
		. "------------ REQUEST END ---------------- \n\n "
	);

	return 1;
}



1;

