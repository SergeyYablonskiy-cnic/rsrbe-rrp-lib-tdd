
package Mock::Metaregistry;

package METARegistry;

=pod

    METARegistry

        Copyright by Key-Systems GmbH

=cut

use strict;
use warnings;
use Socket;
use Clone qw(clone);
use base qw(Serverd::Skel);
use DB;
use JobQueue;
use Transaction;
use PTF;
use PTF::Schema;
use PTF::ErrorHelpText;
use ZoneAccess;
use RegistryAccounts;
use Command;
use Registrar;
use Event;
use EMail;
use Promotion;
use Price;
use Table::Properties;
use Table::RegistrarProperties;
use Table::Extensions;
use strtime qw(str2time time2str min_strtime max_strtime);
use Tool::Monitor;
use Data::Dumper;
use Whois::StdParser;
use MIME::Base64;
use Tool::IDN;
use Tool::DNSSEC;
use SyntaxChecks;
use Domain::Tools qw(checkDomainSyntax);
use Domain;
use Encode::Detect;
use Encode;
use MREG::DateTime;
use Tool::Random;
use MREG::ContactProperties;
use MREG::NameserverProperties;
use Contact::Tools;
use EPP::Tools qw();
use MREG::Registry qw(all);
use ERRP::IcannERRP;
use Whois::WhoisPrivacy;
use Scalar::Util qw(looks_like_number);
use MREG::Backorder;
use MREG::ContactVerificationProperties;
use MREG::Config;
use MREG::DomainRegistryProgramm;
use Tool::SSL;
use MREG::Applications;
use MREG::Lib;
use MREG::IcannOwnerChange;
use MREG::IcannTransfer;
use MREG::StrictContactValidation;
use MREG::Opmode;
use MREG::API::User;
use MREG::JSON;
use MREG::TransferProgress;
use MREG::Trustee;
use MREG::API::Source;
use MREG::Blocklist;
use Jobs;
use Net::CIDR;
use Tool::FTP;
use Tool::PasswordCrypt;
use SSL::Certificate;
use SSL::CertificateContact;
use SSL::CertificateDomain;
use SSL::CertificateOrder;
use SSL::CertificateChain;


require Lib::init;
require Lib::pattern;
require Lib::tools;
require Lib::XPTF;
require Lib::Contact;
require Lib::ContactHistory;
require Lib::ContactPreChecks;
require Lib::DomainHistory;
require Lib::DomainSync;
require Lib::Domain;
require Lib::Event;
require Lib::ACL;
require Lib::Job;
require Lib::Trademark;
require Lib::ERRP;
require Lib::DomainPinLock;
require Lib::DomainApplication;
require Lib::Trustee;
require Lib::Fee;
require Lib::DomainAftermarket;
require Lib::RegistrarSession;
require Lib::Registrar;
require Lib::Homer;
require Lib::Nameserver;


$PTF::Response::showColumns = 1;

use SSL::Helpers;
use Table::Template;


our $VERSION = '1.1.0';
my $server_name = 'metaregistry';
# my $arg1 = $ARGV[0];
my $arg1 = 'debug';
our $OPMODE = 'DEV';

my $mreg_config = MREG::Config->new();
our $mreg_name = $mreg_config->mreg_name || die 'No mreg_name defined';
our $rootuser = $mreg_config->root_user || 'rrpproxy';


## Global vars
my $appName = "METAregistryServer";
my $hostname = `hostname`;
$hostname =~ s/\s*$//;
my %commandHash;
our $commandHash = {};
my %hookHash;
my @commands;
my %loadLibs;
my @zones = ();
our $log_request = "";
our $job;
our $PTF;

my $lastlock = "";
my $EOL = "\015\012";
my $defaultUser = "NULL";
my $cuser = undef;
my $sth;
my @row;

our $db;
my $dbh;
our $transaction;
our $zoneaccess;
our $registrars;
our $schema;


$schema = new PTF::Schema($OPMODE);

# singleton 
my $SELF = undef;



# Load enabled commands
sub new {
		my $class = shift;

		# singleton 
		return $SELF if $SELF;

		my %p = @_;

		my $self = bless {
			project_dir  => $p{project_dir},
			config       => $mreg_config,
			name         => $mreg_name,
			rootuser     => $rootuser,

			conf_file      => '/etc/serverd/metaregistry.conf',
			log_file       => 'Sys::Syslog',
			syslog_logsock => 'unix',
			syslog_ident   => 'RRP_metaregistry_MOCK',
			syslog_logopt  => 'pid|cons',
			serverd_opmode => 'DEV',

		}, $class;


		my $commandHash = $self->require_commands( $p{load_commands} );
		$self->load_commands($commandHash);
		$self->createSession;

		$SELF = $self;

		return $self;

}


sub require_commands {
	my $self = shift;
	my $command_list = shift;

	my $Bin = $self->{project_dir};

	my %load_commands = map {lc $_ => 1 } @$command_list;

	foreach my $cmd (sort keys %$schema)
	{
		my $command = $schema->{$cmd}{NAME};
		my $lib = $command;

		next unless exists $load_commands{ lc $lib };

		if( -l $Bin."/commands/$lib.pl" )
		{
			$lib = readlink $Bin."/commands/$lib.pl";
			$lib =~ s/\.p(l|m)$//;
		}

		# Load Commands 
		eval {
			if( !defined $loadLibs{$lib}) 
			{
				require $Bin."/commands/$lib.pl";
				$loadLibs{$lib} = 1;
			}
			$commandHash{lc($command)} = \&{'execCommand_'.$command} if defined $command;
			$self->require_hooks($lib);
		};

		die "Can't load commands $Bin/command/$lib.pl\n$@" 
			if $@;

		

		push @commands, $command;
		
	}

	return \%commandHash;
}


sub load_commands {
	my $self = shift;
	my $commands = shift || {};

	foreach ( keys %{$commands} ) {
		$Serverd::Skel::commandHash->{uc $_} = $commands->{$_};
	}

	return 1;
}

### ==============> HERE <==================



# ### Start server ###
# METARegistry->load_commands(
# {
# 	'arg1'=>$arg1,
# 	'server_name'=>$server_name,
# 	'OPMODE' => $OPMODE,
# }
# ,\%commandHash);

#################################################



sub require_hooks {
	my $self = shift;
	my $lib = shift;

	my $Bin = $self->{project_dir};

	my $hook_path = $Bin."/hooks/$mreg_name/$lib.pm";
	if( -f $hook_path )
	{
		print STDERR "Load hook: $hook_path\n" if $ENV{DEBUG};
		require $hook_path;
	}
}

sub createSession 
{
	my $self = shift;

	$self->log(3,"Start Session\n");

	$self->{OPMODE} = $OPMODE;

	# Init database and classes
	$self->initDB();

	# ptf_openUDPSocket();

	$self->log(3,"Session successfully load") if $ENV{'DEBUG'};

	return 0;
}

sub initDB
{
	my $self = shift;

	$self->{OPMODE} = $OPMODE;
	$self->{MREG_NAME} = $mreg_name;
	$self->{LOGINDEX} = undef;

	my $db_init_start = Time::HiRes::time();

    # Init database
	$self->{DB} = new DB({MASTER=>1,SLAVE1=>1, OPMODE=>$OPMODE});
    $db = $self->{DB};

	$self->{DBH} = $db->master();
    $dbh = $self->{DBH};

	my $db_init_runtime = int((Time::HiRes::time() - $db_init_start) * 100) / 100;

	$rootuser = $db->{'ROOTUSER'} || 'rrpproxy';
    $self->{ROOTUSER} = $rootuser;

	#init_Database($OPMODE,$dbh);

    $self->log(3,"Database successfully load") if $ENV{'DEBUG'};

	$self->{SCHEMA} = $schema;

	my $transaction_init_start = Time::HiRes::time();

    # Init basic classes 
	$self->{TRANSACTION} = new Transaction($dbh,{
        'loadcurrencies' => 1 , 
        'initcurrencies' => ['EUR','USD','CHF','PLN','AUD','NZD','GBP'] 
    });
    $transaction = $self->{TRANSACTION};
	
	my $transaction_init_runtime = int((Time::HiRes::time() - $transaction_init_start) * 100) / 100;

	my $zoneaccess_init_start = Time::HiRes::time();

	$self->{ZONEACCESS} = new ZoneAccess($dbh); 
    $zoneaccess = $self->{ZONEACCESS};

	my $zoneaccess_init_runtime = int((Time::HiRes::time() - $zoneaccess_init_start) * 100) / 100;

	my $registryaccounts_init_start = Time::HiRes::time();

	$self->{REGISTRYACCOUNTS} = new RegistryAccounts({
		'DB' => $self->{DB},
		'DBH' => $self->{DBH},
		'ZONEACCESS' => $self->{ZONEACCESS},
	});

	$self->{REGISTRYACCOUNTS_CACHE}{CONTACTEXTENSIONS}           = ();
	$self->{REGISTRYACCOUNTS_CACHE}{PERSISTENTCONTACTEXTENSIONS} = ();

	foreach my $regAccName (keys(%{$self->{REGISTRYACCOUNTS}{registryaccounts}}))
	{
		my $registryAccount = $self->{REGISTRYACCOUNTS}{registryaccounts}{$regAccName};
		next if !defined($registryAccount->registry);
		if ($registryAccount->registry->contactExtensions())
		{
			foreach my $extension ($registryAccount->registry->contactExtensions())
			{
				push(@{$self->{REGISTRYACCOUNTS_CACHE}{CONTACTEXTENSIONS}}, $extension);
			}
		}
		if ($registryAccount->registry->persistentContactExtensions())
		{
			foreach my $extension ($registryAccount->registry->persistentContactExtensions())
			{
				push(@{$self->{REGISTRYACCOUNTS_CACHE}{PERSISTENTCONTACTEXTENSIONS}}, $extension);
			}
		}
	}
	
	my $registryaccounts_init_runtime = int((Time::HiRes::time() - $registryaccounts_init_start) * 100) / 100;

	my $registrars_init_start = Time::HiRes::time();

	$self->{REGISTRARS} = new Registrar($dbh);
    $registrars = $self->{REGISTRARS};

	my $registrars_init_runtime = int((Time::HiRes::time() - $registrars_init_start) * 100) / 100;

	my $promotion_init_start = Time::HiRes::time();

	$self->{PROMOTION} = new Promotion($dbh,$self->{TRANSACTION});
	
	my $promotion_init_runtime = int((Time::HiRes::time() - $promotion_init_start) * 100) / 100;

	my $price_init_start = Time::HiRes::time();

	$self->{PRICE} = new Price($dbh, $self->{ZONEACCESS}, $self->{TRANSACTION}, $self->{PROMOTION}, $self->{REGISTRARS});

	my $price_init_runtime = int((Time::HiRes::time() - $price_init_start) * 100) / 100;

	my $ptf_init_start = Time::HiRes::time();

    $self->{PTF} = new PTF({
        OPMODE => $OPMODE,
        DB => $db,
        ZONEACCESS => $self->{ZONEACCESS},
		REGISTRYACCOUNTS => $self->{REGISTRYACCOUNTS},
    });
    $PTF = $self->{PTF};

	$self->{MREGLIB} = new MREG::Lib(
		config => $mreg_config,
		opmode => $OPMODE,
		db => $db,
		dbh => $dbh,
		ptf => $self->{PTF},
		log => $self->libLog(),
	);

	my $ptf_init_runtime = int((Time::HiRes::time() - $ptf_init_start) * 100) / 100;

	my $total_runtime = int((Time::HiRes::time() - $db_init_start) * 100) / 100;

	$self->log(2,"initDB runtimes: db:$db_init_runtime transaction:$transaction_init_runtime zoneaccess:$zoneaccess_init_runtime ".
		"registryaccounts:$registryaccounts_init_runtime registrars:$registrars_init_runtime promotion:$promotion_init_runtime ".
		"price:$price_init_runtime ptf:$ptf_init_runtime total:$total_runtime");

    $self->getACLLocations();

    return 0;
}

sub checkSession {
	my $self = shift;

	foreach (qw(DB DBH ROOTUSER TRANSACTION ZONEACCESS REGISTRYACCOUNTS REGISTRARS PROMOTION PRICE PTF))
	{
		unless( defined $self->{$_} )
		{
			$self->log(0,"Error in checkSession: \$self->{$_} is undefined");
			return 1;
		}
	}

	unless( $self->{DBH}->ping )
	{
		$self->log(0,'Error in checkSession: DBH->ping failed');
		return 1;
	}

	$self->{DB}->checkDatabaseConnections();

	return 0;
}

sub handleRequest 
{
	my $self = shift;

  my $request = (ref($_[0]) ? shift : undef);
	my $log_request = shift || '';

	KS::Test::Logger->get_logger->info(
		'Request <= '.$request->commandname .', '
		.'socket: ' . ( $request->option('SOCKET') || '-') .', '
		.'rid: '  . ( $request->rid || '-' ) 
	);

	# Reconnect to db if connection lost	
	if( $self->checkSession() )
	{
		$self->log(0,"Error: Database connect is broken! Reconnect");
        
        $self->initDB();
	}

	if( ref $request eq 'HASH')
	{
		$request->{COMMAND}{_CONFIG} = $request->{RRPPROXY} || $request->{METAREGISTRY};
		$request = $request->{COMMAND};

		$log_request = PTF::Request::toString($request);
	}
	elsif( defined $request )
	{
		$log_request = $request->toString();
	}
	else
	{
		$request = PTF::Request->parse(\$log_request);
	}

	print STDERR "REQUEST: ".Dumper($request) if $ENV{DEBUG};

	# Check ptf command syntax
	if( $ENV{PTFCHECK} )
	{
		$self->{PTFXCLIENT} = new PTF::XClient({'OPMODE' => $self->{OPMODE}, 'LoadCheckMRAL' => 1, 'checkMRAL' => 1});

		my $response = $self->{PTFXCLIENT}->checkCommand($request);

		if( $response )
		{
			$response->set('PTFCHECK' => 'error');

			return $response;
		}
	}

	$self->{JOBQUEUE} = undef;
	$self->{FINISHJOB} = 0;

	## Load command from queue and execute
	if( uc($request->{'COMMAND'}) eq 'EXECUTEJOB' )
	{
		$self->{FINISHJOB} = $request->{JOBID};
		return getResponse(549) if !$self->{FINISHJOB};

		$self->{JOBQUEUE} = new JobQueue($dbh,{'log_index' => $self->{FINISHJOB} });
		$self->{JOBQUEUE}->read();

		return getResponse(549,'Can\'t lock job') 
			if !$self->{JOBQUEUE}->lock();
		
		$request = PTF::Request->parse($self->{JOBQUEUE}->get('command_block'));

		# Remove session id from request and set user for authentication
		if( $request->option('SESSIONID') )
		{
			$request->option('USER' => $self->{JOBQUEUE}->get('registrar'));
			$request->option('SESSIONID' => undef);
		}
		
		$log_request = $request->toString();

		print STDERR 'ExecuteJob'.Dumper($request,$log_request);

		my $statuscode = $self->{JOBQUEUE}->get('statuscode') || '';

		if( !$statuscode || $statuscode != 10 || !$request->{COMMAND} )
		{
			$self->{JOBQUEUE}->unlock();
			return getResponse(545,'No job pending!');
		}

		$log_request =~ s/^JOBQUEUE.*$/JOBQUEUE = finish $self->{FINISHJOB}/img;
		$request->{JOBQUEUE} = 'finish';

		print STDERR "FINISH OLD REQUEST (jobid:$self->{FINISHJOB} statuscode:$statuscode:\n".$request->toString."\n" if $ENV{DEBUG};
	}

	my $user = lc($request->option('USER') || $defaultUser);
	my $noquota = $request->option('NOQUOTA') || 0;

	# Get registrar and user session table
	if( $request->option('SESSIONID') )
	{
		my $sessionData = eval { $self->getSessionData($request->option('SESSIONID')); };
		if( my $error = $@ )
		{
			return $error if ref($error) eq 'PTF::Response';

			$self->log(0, "getSessionData error: $error");

			return PTF::Response->new(549);
		}

		# Set user with acl user and parent
		$user = $sessionData->{'registrar'} . ($sessionData->{'user'} ? ':' . $sessionData->{'user'} : '');
	}

	# Split user in real user (registrar), acl user and acl parent
	$self->{APIUSER} = MREG::API::User->new(name => $user);
	$self->{USER} = $self->apiuser->user;
	$self->{USERNAME} = $self->apiuser->acluser;

	# Set apiuser in MREG::Lib  
	$self->lib->apiuser($self->apiuser);
	
	### Hard linked Singup registrar ACL setting
	if ($self->{REGISTRARS}->getRegistrarStatus($user) =~ /^PENDING$/io) {
		$self->apiuser->aclparent('rrpproxy');
		$self->apiuser->acluser('signup');
	}

	# Check user ACL access
	return $_ if $_ = $self->checkACLAccess($request);

	# If is parent then execute command as subuser. Do not use Subuser parameter if value equals executing user -> fixes #29867
	if (defined($request->{'SUBUSER'}) && uc($request->{'SUBUSER'}) ne uc($self->{USER}))
	{
		my $subuser = lc($request->{'SUBUSER'});
		return getResponse(531,"Invalid subuser: $subuser") if $self->{REGISTRARS}->recursiveCheckValidSubuser($self->{USER},$subuser) == 0;
		$self->apiuser->user($self->{USER} = $subuser);
	}

	$self->{SESSION} = {
		CLTRID => $request->{CLTRID},
		RETURN_CLTRID => defined($request->{CLTRID}) || defined($request->option('EPP')),
		SVTRID => $request->option('SVTRID'),
		SOURCE => MREG::API::Source->new(name => ($request->option('SOURCE') || '')),
		EPP => $request->option('EPP'),
	};
	$self->{SESSION}{CLTRID} = JobQueue::getUUID() if !$self->{SESSION}{CLTRID} || $self->{SESSION}{CLTRID} eq 'AUTO';
	$self->{SESSION}{SVTRID} = JobQueue::getUUID() if !$self->{SESSION}{SVTRID} || $self->{SESSION}{SVTRID} eq 'AUTO';
	$self->{SESSION}{epp} = $self->{SESSION}{EPP};

	$self->{SESSION}{CLTRID} = substr($self->{SESSION}{CLTRID},0,64);

    $self->{JOBQUEUE} = new JobQueue($dbh,{
        'registrar' => $self->{USER},
        'host' => $hostname,
        'cltrid' => $self->{SESSION}{CLTRID},
		'svtrid' => $self->{SESSION}{SVTRID},
        'source' => $self->{SESSION}{SOURCE},
    }) if !defined $self->{JOBQUEUE};
    $job = $self->{JOBQUEUE};

    # convert roid
    $self->convertRoids($request);

    $cuser = $user = $self->{USER};

	# Disable quota limit for command Describe and QueryEventList
	$noquota = 1 if $request->{COMMAND} =~ /^(Describe|QueryEventList)$/i;

	# User Quota Limits
    if ( ($user ne $defaultUser) && !$noquota ) 
	{
		my $class = 'DEFAULT';
		$class = 'CHECKDOMAIN' if $request->{COMMAND} =~ /^CheckDomain(s)?/i;

		if( $request->option('SETACCESSCOUNT') )
		{
			LimitCount("$user:$class:".int($request->option('SETACCESSCOUNT') || 1));
			return "[RESPONSE]\ncode = 422\ndescription = Abuse detected; account has been temporarily locked; Please standby some minutes.\n";
		}
		else
		{
			LimitCount("$user:$class");
		}

        ### User blacklist ###
        if( $user =~ /^(aaahosting)$/i )
        {
            return getResponse(541,'contract terminated')
                if $request->{COMMAND} !~ /^(ChargeCreditcard|RenewDomain|TransferDomain|SetDomainTransferMode|StartSession)$/i;

            return getResponse(541,'contract terminated')
                if $request->{COMMAND} =~/^RenewDomain$/i && !defined $request->{AUTO};
        }
	}

    $self->{LOGINDEX} = undef;
    my $start_time = time();

	if( $self->{FINISHJOB} )
	{
		$self->{LOGINDEX} = $self->{FINISHJOB};
	}
	elsif($request->{COMMAND} !~ /^(Check|Query|Status|Get)/i && 
		$request->{COMMAND} !~ /(AERO_CheckENS|ConvertCurrency|Describe|GNR_NAME_CheckSLD|TRAVEL_StatusUIN|FindDNSZone|StartSession|StopSession|AddEvent|DomainPrice|Poll|ExportDNSZone)/i) 
	{
		### TODO: Dont create commandlog on transferdomain action=query

        my $zone = ($request->{DOMAIN} ? getZone($request->{DOMAIN}, $user) : undef);
		$zone = ($zone ? reverse($zone) : 'unknown');
	
        $self->filterLog(\$log_request);

        $job->set({'zone_reverse' => $zone, 'domain' => $request->{DOMAIN}});
		$job->parse_command($log_request);
		$self->{LOGINDEX} = $job->createCommandLog;

		if( !$job->create )
        {
            my $runtime = time() - $start_time;
			my $response = new PTF::Response(541,'CLTRID is not unique');

			if( $dbh->err )
			{
				$self->log(0,"SQL Error: ".$dbh->errstr); 
				$response = new PTF::Response(549,'Internal server error (create job)');
			}

            $response->{CLTRID} = $self->{SESSION}{CLTRID} if defined $self->{SESSION}{CLTRID};
            $response->{SVTRID} = $self->{SESSION}{SVTRID} if defined $self->{SESSION}{SVTRID};
            $dbh->do(
                "UPDATE commandLog SET code=".$dbh->quote($response->{CODE}).", description=".$dbh->quote($response->{DESCRIPTION}).", ".
                "runtime=".$dbh->quote($runtime).", timeout=0, response_block=".$dbh->quote($response->getResponse())." ".
                "WHERE log_index=".$dbh->quote($self->{LOGINDEX})
            );
            return $response;
        }
    }
 
 	# Convert X- contact names
	$self->convertContactNames($request);

	my $log_response = $self->execCommand( $user, $request );
	my $response = (ref $log_response ? $log_response : \$log_response) ;

	# remove remaining locks...
	$dbh->do("UNLOCK TABLES;");

	unlock_object();

    ### EPP clTRID ###
    if( defined $self->{SESSION}{CLTRID} && $self->{SESSION}{RETURN_CLTRID} )
    {
		if( ref $response ne 'SCALAR' )
		{
			$response->set(CLTRID => $self->{SESSION}{CLTRID}, SVTRID => $self->{SESSION}{SVTRID});
		}
		else
		{
			$$response .= "cltrid=".$self->{SESSION}{CLTRID}."\n";
			$$response .= "svtrid=".$self->{SESSION}{SVTRID}."\n";
		}
    }

	# Response Filter
	if( ref $response eq 'PTF::Response' )
	{
		delete $response->{EPPCODE};
	}

	# Check ptf response syntax
	if( $ENV{PTFCHECK} && $self->{PTFXCLIENT} )
	{
		my $responseError = $self->{PTFXCLIENT}->filterResponse($response,$request->{COMMAND});

		if( $responseError )
		{
			print STDERR "*** PTF Check response errors ***\n$responseError\n" if $ENV{DEBUG};
		}
	}

    if ($self->{LOGINDEX}) 
	{
		my $runtime = time() - $start_time;

		#my $log_response = '';
		if( ref $response eq 'SCALAR' )
		{
			$response = PTF::Response->parse($response);
		}
		else
		{
			$log_response = $response->toString();
		}

	    my $timeout = 0;

	    if( $response->{CODE} == 421 && $response->{DESCRIPTION} =~ /\(timeout\)/ ) 
		{
    	    $timeout = 1;
	    }

		$job->set({
			'processing' => 0,
			'runtime' => $runtime,
			'timeout' => $timeout,
		});

		if( $job->get('statuscode') == 10 && $self->{FINISHJOB} )
		{	
			$job->set({'statuscode' => 15});
			$self->finishJob($response);
		}
		elsif( $job->get('statuscode') == 1 )
		{
            $job->delete();

			# Remove spam from commandLog
			if( $response->{CODE} == 554
			 || ( $response->{CODE} == 540 && $request->{COMMAND} =~ /^(AddDomain|AddNameserver)$/i ) 
			 || ( $response->{CODE} == 545 && $request->{COMMAND} =~ /^(DeleteDomain|DeleteNameserver|DeleteContact|ModifyDomain|ModifyDomain|ModifyNameserver|SetDomainRenewalMode|TransferDomain|PushDomain)$/i )
			 || ( $request->{COMMAND} =~ /^(Add|Renew|Reissue)Certificate$/i && defined $request->{'CHECKONLY'} && $request->{'CHECKONLY'} == 1 ))
			{
				$job->deleteCommand();
			}
		}

		$response->{'RESPONSE'} = $log_response;
		$job->finishCommand($response);
		delete $response->{'RESPONSE'};
    }

	# if source is WI, then try to get help text
	# and forward this text to WI
	if ($request->{COMMAND} =~ /^(Add|Renew|Modify|Delete|Transfer|Trade)Domain$/i && 
		$self->{SESSION}{SOURCE}->interface() && $self->{SESSION}{SOURCE}->interface() =~ /^WI15_USER$/i)
	{
		my $helptext = PTF::ErrorHelpText->new (opmode => MREG::Opmode->new($OPMODE), dbh => $dbh);
		my $zone = getZone ($request->{DOMAIN}, 'REGISTRY');
		my $regacc = $self->ptf->getRegistryAccount({ZONE => $zone, REGISTRAR => $user, RECURSIVE => 1});

		eval 
		{
			$helptext->addHelpTextToResponse (
				$response,
				$request->{COMMAND},
				$zone,
				$regacc,		# Registryaccount-Object!!!
			);
		};
		$self->log(1,'addHelpTextToResponse($response, '.($request->{COMMAND} || '').', '.($zone || '').', '.($regacc || '').') error:'.$@)
			if $@;
	}

	if( ref $response eq 'SCALAR' )
	{
		$$response = "[RESPONSE]\n$$response\n" if $$response !~ /^\[RESPONSE\]/;
	}
    
    return (ref $response ? $response : \$response);
}

sub execCommand {
	my $self = shift;
	my $user = shift;
	my $request = shift;

	my $retain = 0;
	if (defined($self->{DATA}{DBTRANSACTION}) && $self->{DATA}{DBTRANSACTION} eq 'RETAIN')
	{
		$retain = 1;
		delete($self->{DATA}{DBTRANSACTION});
	}

	my $response = $self->SUPER::execCommand( $user, $request, @_ );

	# Rollback open transactions
	if( !$self->{DBH}->{AutoCommit} && !$retain)
	{
		$self->log(2,"SQL Rollback transaction for command: ".$request->{COMMAND}." (log_index: ".($self->{LOGINDEX} || 'undef').")");
		$self->{DBH}->rollback or $self->log(0,"SQL Rollback failed:",$self->{DBH}->errstr);
	}

	return $response;
}

## Execute hook
sub execHook 
{
    my $self = shift;
	my $hook = shift;

	my $func = 'execHook_'.$hook;
	if ( METARegistry->can($func)  ) 
	{
		my $resp;

		$self->log(4,"Exec hook $func") if $ENV{DEBUG};

		eval { $resp = $self->$func(@_); };
		
        $self->log(0,"Exec hook error: $@") if $@;
		if( $@ =~ /^Request time out/i )
		{
			alarm(0);
			return "code=423\ndescription=Command failed (timeout)\n";
		}

		return getResponse( 549 ) if !defined $resp;
		return $resp;
	} 
	else 
	{
		$self->log(4,"Skip hook $func") if $ENV{DEBUG};
		return 0;
	}
}

## Split request to hash
sub splitRequest 
{
	return &Serverd::Skel::splitRequest(@_);
}

sub lock_object 
{
    my $object = shift;
    my $locktimeout = 5;
	my $lockprefix = $db->{'config'}{'db_name_MASTER'};
    $lastlock = $lockprefix.'::'.$object;
    my @r = $dbh->selectrow_array("SELECT GET_LOCK(".$dbh->quote("$lastlock").", $locktimeout)");
    return shift @r;
}

sub unlock_object 
{
    return 0 if !length($lastlock);
    my @r = $dbh->selectrow_array("SELECT RELEASE_LOCK(".$dbh->quote("$lastlock").")");
    $lastlock = "";
    return shift @r;
}

sub getRegistryAccount {
    my $zone = shift;
    my $registrar = shift;
	return $zoneaccess->getRecursiveRegistryAccount($zone, $registrar);
}

sub getRegistryAccountForDomain {
    my $domain = shift;
    my $registrar = shift;
	return $zoneaccess->getRegistryAccountByDomain($domain, $registrar);
}
sub convertFee {
	my $fee = shift;
	my $currency = shift;
	my $return_currency = shift || 'USD';
	return $transaction->convertCurrency($fee, $currency, $return_currency);
}

sub getResponse {
    my $self = (ref($_[0]) eq 'METARegistry' ? shift : undef);
	return Serverd::Skel::getResponse($self,@_);
}

sub appendRequest {
    $log_request .= "\n".shift;
}

sub getZone {
    my $domain = shift || return undef;
    my $user = shift;
	$user = $cuser if !defined($user);
    my $zone = $zoneaccess->getZone($domain);
	return $zone if !defined($user) || uc($user) eq 'REGISTRY';
	return undef if !$zoneaccess->checkActiveZoneAccess($zone, $user);
	return $zone;
}

sub getParent {
	my $domain = shift || return undef;

	return $zoneaccess->getParentDomain($domain);
}

sub checkIP {
	# 0 - is not a valid IP address
	# 1 - is a valid IP address
	my $ipaddress = shift;
	return 1 if &SyntaxChecks::normalizeIPAddress($ipaddress);
	return 0;
}

sub restrictedIP {
	# 0 - is not restricted
	# 1 - is restricted
    my $ipaddress = shift;
    return &SyntaxChecks::isRestrictedIP($ipaddress);
}

sub reformatAmount {
    my $amount = shift;
	return $transaction->reformatAmount($amount);
}

sub getVAT {
	my $user = shift;
	my $price = shift;
	return $transaction->getVatAmount($price, $user);
}

sub filterLog_hook {
	my $self = shift;
	my $logref = shift;
	$$logref =~ s/((?:^|\n)cardnumber[\t ]*=[\t ]*\d{4})(\d*)(\d{4}(?:\n|$))/$1XXXXXXXX$3/mig;
	$$logref =~ s/((?:^|\n)creditcard-cardnumber[\t ]*=[\t ]*\d{4})(\d*)(\d{4}(?:\n|$))/$1XXXXXXXX$3/mig;
	$$logref =~ s/((?:^|\n)card\-number[\t ]*=[\t ]*\d{4})(\d*)(\d{4}(?:\n|$))/$1XXXXXXXX$3/mig;
	$$logref =~ s/((?:^|\n)cardcvc2[\t ]*=[\t ]*)(.*)(\n|$)/$1XXXX$3/mig;
	$$logref =~ s/((?:^|\n)creditcard-cardcvc2[\t ]*=[\t ]*)(.*)(\n|$)/$1XXXX$3/mig;
	$$logref =~ s/((?:^|\n)card\-cvc2[\t ]*=[\t ]*)(.*)(\n|$)/$1XXXX$3/mig;
	$$logref =~ s/((?:^|\n)password[\t ]*=)[\t ]*.*(\n|$)/$1\*\*\*\*\*$2/mig;
	$$logref =~ s/((?:^|\n)ftppassword[\t ]*=)[\t ]*.*(\n|$)/$1\*\*\*\*\*$2/mig;
	$$logref =~ s/((?:^|\n)newpassword[\t ]*=)[\t ]*.*(\n|$)/$1\*\*\*\*\*$2/mig;
	$$logref =~ s/((?:^|\n)ccpayment-ftppwd[\t ]*=)[\t ]*.*(\n|$)/$1\*\*\*\*\*$2/mig;
	$$logref =~ s/((?:^|\n)ccpayment-merchpw[\t ]*=)[\t ]*.*(\n|$)/$1\*\*\*\*\*$2/mig;
	$$logref =~ s/((?:^|\n)ccpayment-msyspwd[\t ]*=)[\t ]*.*(\n|$)/$1\*\*\*\*\*$2/mig;
	$$logref =~ s/((?:^|\n)pppayment-password[\t ]*=)[\t ]*.*(\n|$)/$1\*\*\*\*\*$2/mig;
	$$logref =~ s/((?:^|\n)pppayment-ftppwd[\t ]*=)[\t ]*.*(\n|$)/$1\*\*\*\*\*$2/mig;
	$$logref =~ s/((?:^|\n)parking-namedrivepassword[\t ]*=)[\t ]*.*(\n|$)/$1\*\*\*\*\*$2/mig;

	$$logref =~ s/((?:\[COMMAND\]\n|.|\n)*ftppassword[\t ]*=)[\t ]*(?:[^\&\n]*)(\&*[^\n]*(?:\n|$))((.|\n)*)/$1\*\*\*\*\*\n$3/mig;
}

# Get PTF instance
sub ptf { shift->{PTF} }

# Get MREG::Lib instance
sub lib { shift->{MREGLIB} }

# Get MREG::API::User instance
sub apiuser { shift->{APIUSER} }

# Get a MREG::Applications instance
sub applications {
	my $self = shift;

	$self->{APPLICATIONS} = new MREG::Applications(dbh => $self->{DBH}, zoneaccess => $self->{ZONEACCESS})
		if !$self->{APPLICATIONS};

	return $self->{APPLICATIONS};
}



1;
