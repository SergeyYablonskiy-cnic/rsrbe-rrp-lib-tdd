package METARegistry;


use strict;
use warnings;
no warnings qw(redefine);

sub SendPTFCommandRaw {
	my $command = shift;

	my $req = PTF::Request->new($command);
	$req->option(SOCKET => getPTFInfo());


	my $res = $req->call;

	return ref $res ? $res->toString : $res;
}



1;

