# *********************************************************************
package METARegistry;
# *********************************************************************



## bool log(int level, list messages)
# redefine metaregistry's log method and forward messages to the test's event.log
# arg "level" - int event level from 0 (error) to 4 (debug)
# arg "messages" - list string of messages for logging
# return true
sub log {
	my $self    = shift;
	my $level   = shift;
	my $message = join('; ', @_) || '!the log message string is empty!';

	my $method = {
		0 => 'error',
		1 => 'warn',
		2 => 'info',
		3 => 'info',
		4 => 'debug'
	}->{$level};

	KS::Test::Logger->get_logger->$method('* '.$message);

	return 1;
}



## obj logger(void)
# return the object KS::Test::Logger
sub logger {
	return KS::Test::Logger->get_logger;
}


1;
