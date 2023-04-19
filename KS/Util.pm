## @file
# @brief utils and tools functions

## @package KS::Util
package KS::Util;
# *********************************************************************

use strict;
use warnings;
use utf8;

use Carp;
use Data::Dumper;
use Encode;


use base "Exporter";

our @EXPORT_OK = qw(my_rand debug trim println);

# our $LOGDIR = '/home/ad.ks.de/sergey.yablonskiy/work/rsrbe-13085-ee-billing-contact/logs';

our %cache = ();


## @method int my_rand([int from, int to])
# Generate int in a range "from .. to"
# @param \c from  - lower end of the range
# @param \c to    - upper end of the (optional)
# @return int new generaited int
sub my_rand
# ----------------------------------------------------------
{
	my ($from, $to) = @_;
	return unless $to 
		? int( rand($from || 1000 + 1) )
		: int( rand($to-$from+1) + $from );
}
# ----------------------------------------------------------



sub println
# ----------------------------------------------------------
{
	print @_, "\n";
}
# ----------------------------------------------------------


## @method string trim(string str)
# remove trailing space-characters
# @return string without trailing space symbols
sub trim
# ---------------------------------------------------------------------
{
	my $val = shift;

	return unless defined $val;
	if (ref $val) { croak 'Trim operation is not allowed for refference object!'; return undef }

	$val =~ s/^\s+//;
	$val =~ s/\s+$//;

	return $val;
}
# ---------------------------------------------------------------------



## @method string trace(void)
# return call trace as string or print it to STDOUT if no return expected
# @return string call trace
sub trace
# ---------------------------------------------------------------------
{
	my $object = $_[1];
	my $i = 1;
	my @callerResult;
	my $projectPath = base_path();
	my $result = "call trace: ".(ref $object)."\n------------------------------------------------\n";
	while (my($package, $filename, $line, $sub) = caller($i++)) {
		last unless $line;
		$filename =~ s/$projectPath//;
		$result .= ($i-1).': '.$filename.':'.$line."\n";
	}
	$result .= "------------------------------------------------\n";
	defined wantarray ? return $result : println $result;
}
# ---------------------------------------------------------------------



## @method string get_dump([hashref|arrayref|string] p)
# @param p - a data structure for a dump. Arrayref/Hashref/Scalarы  are allowed
# @return string of the dump
sub get_dump
# ---------------------------------------------------------------------
{
	local $Data::Dumper::Indent = 1;
	my $dump = Dumper(shift);
	# $dump =~ s/\n/__n__/g;
	# $dump =~ s/\s{4}/ /g;
	# $dump =~ s/__n__/\n/g;

	return $dump;
}
# ---------------------------------------------------------------------


## @method void debug([hashref|arrayref|string]);
# write a data-dump into debug-log file (opt/logs/debug.log)
# @param p - data structure for a dumping
sub debug
# ----------------------------------------------------------
{

	# opt/logs
	# my $fpath = abs_path( $cache{base_path} =~ /tld/ ? '../../logs' : '../logs') . '/debug.log'; 
	my $fpath = abs_path( base_path() =~ /tld/ ? '../../logs' : '../logs') . '/debug.log'; 

	# create dump
	for my $data (@_) {
		$data = '' unless defined $data;
		my $str = ref $data ? get_dump($data) : $data;
		my $rand = sprintf("%.0f", rand(100000));

		my $openFlag = Encode::is_utf8($str) ? '>>:utf8' : '>>:raw';

		# my $openFlag = utf8::is_utf8($str) ? '>>:utf8' : '>>';
		open(W, $openFlag, $fpath) or die("Can not open debug.log file '".$fpath."': ".$!);
		print W "\n-- $rand START -------------------- \n" if ref $data;
		print W $str;
		print W "\n-- $rand END -------------------- " if ref $data;
		print W "\n";
		# uncomment for search debug call
		# print W KS::Util::trace;
		close W;

	}

	return 1;

}
# ----------------------------------------------------------


## @method bool debug_trace([hashref|arrayref|string])
# print to the debug.log income arguments and a calltrace
sub debug_trace
# ----------------------------------------------------------
{
	debug( @_, trace() );
}
# ----------------------------------------------------------


## @method string readFile(string fpath[, hash %p])
# read the file into string
# @param \c fpath  - the file path absolute or relative (from the project's root directory)
#                    \c openned filehandler also supported, is it usefull for use in open2 function from the package IPC::Open2
# @param \c p      - extra params:
#                    \c utf8 - if true, the data will return with upper utf-8 flag
# @note please use eval{} for catching errors
# @return string file content
sub read_file
# ----------------------------------------------------------
{
	my $path = shift;
	my %p = @_;

	die('Can not read data from file: path value is empty') unless $path;

	local $/ = undef;
	my $content;

	if ( ref $path eq 'GLOB' ) {
		$content = <$path>;
		return $content;
	}

	$path = KS::Util::abs_path($path);
	unless (-e $path) { return croak ("ERROR: file '$path' not found.") };

	open(F, '<' .($p{utf8} ? ':utf8' : '') , $path) or croak('Can not open file : '.$path.'. '.$!);
	$content = <F>;
	close F;

	return $content;
}
# ----------------------------------------------------------



## @method string read_data()
# Read and return data from the  __DATA__ section
# @return string from a __DATA__ section
sub read_data
# ----------------------------------------------------------
{
	my $handler = (caller)[0].'::DATA';
	my $content = join "", <$handler>;
	return trim($content);
}
# ----------------------------------------------------------




## @method string base_path()
# determinate a base path to project (without ended slash)
sub base_path
# ----------------------------------------------------------
{
	return $cache{base_path}
		if $cache{base_path};

	use FindBin('$Bin');

	# ../opt/metaregistry5
	# ../opt/tld/xx
	# ../opt/batch-mreg
	my @dir_list = $Bin ? $Bin : sort @INC;

	my ($path) = grep { m[ /opt/(meta|batch|tld|cron|tools) ]x } @dir_list;

	$path =~ m[ (.*/opt)/([^/]+)/?([^/]+)? ]x;
	$path = $1.'/'.$2;
	# tld projects are placed in tld-subdir
	$path .= '/'.$3 if $2 eq 'tld';

	die ('Can not define the base path in the directories list: '.(join "\n", @dir_list).'.') unless $path;
	$cache{base_path} = $path;

	return $cache{base_path};
}
# ----------------------------------------------------------


## @method string abs_path(string fname)
# return an absolute file path
# @param fname - string file path путь к файлу. Absolute path is also supported (in that case input string will return)
# @return string absolute file path
sub abs_path
# ----------------------------------------------------------
{
	return $_[0] =~ /^\// ? $_[0] : KS::Util::base_path() . '/'.$_[0];
}
# ----------------------------------------------------------



## @method bool write_file(string fpath, string content)
# write the input string into file 
# @param fpath   - string file path
# @param content - string content
# @retval TRUE for sucess result
# @retval FALSE if an error occured
sub write_file
# ----------------------------------------------------------
{
	my ($fpath, $content) = @_;

	$fpath = KS::Util::abs_path($fpath);

	# if the file directory exists
	my ($fdir) = $fpath =~ m{ (.+?)/[^/]+$ }x;

	unless ($fdir) { return croak("Can not define file directory by fpath '".$fpath."'.") };
	unless (-e $fdir) { return croak("File directory ".$fdir." does not exists.") };

	my $openFlag = Encode::is_utf8($content) ? '>:utf8' : '>:raw';

	open(W, $openFlag, $fpath) or die("Can not open file for write '".$fpath."': ".$!);
	print W $content;
	close W;


	return 1;

}
# ----------------------------------------------------------



## bool in_array_str(str needle, arrayref haystack)
# searches for needle in haystack
# retval TRUE if the needle found in the haystack
# retval FALSE otherwise
sub in_array_str {
	my ($str, $array) = @_;
	for (@$array) {
		return 1 if $str eq $_;
	}
	return 0;
}



## string timestamp(void)
# return current timestamp string in format 'YYYY-MM-DD hh:mm:ss'
sub timestamp {
	return format_date(time, 'YYYY-MM-DD hh:mm:ss');
}



# param "time" is required  (now, +1d, +2M и т.д.)
# two-year-digist format is not supported
sub format_date
# ----------------------------------------------------------
{
	my ($time, $format) = @_;

	$format = 'YYYY-MM-DD' unless $format;

	my $pattern = '';
	my $letter  = '';
	my @order;
	my $countLetter = 0;

	# determinate the sprintf format
	for (split //, $format, -1) {

		if ($letter ne $_) {

			if ($countLetter) {
				$pattern .=  '%0' . $countLetter . 'd';
				$countLetter = 0;
			}

			if ($_ !~ /[YMDhms]/) {
				$pattern .= $_;
				next
			}

			$letter = $_;
			push @order, $letter; # the order
		}

		++$countLetter;
	}

	$time = expire_calc($time);
	my %data;
	@data{qw/s m h D M Y/} = localtime($time);
	$data{Y}+=1900;
	$data{M}++;

	return sprintf($pattern, @data{(@order)});
}
# ----------------------------------------------------------



# int expire_calc(string $tm)
# This routine creates an expires time exactly some number of
# hours from the current time.  It incorporates modifications from Mark Fisher.
# Format for time $tm can be in any of the forms... ([timestamp][+/-offset])
# timestamp may be:
#    "now"      string -- expire immediately
#    timestamp  int    -- seconds after 1970 year
# offset may be:
#   "+1D"   -- in 1 day
#   "+3M"   -- in 3 months
#   "+2Y"   -- in 2 years
#   "+180s" -- in 180 seconds
#   "+2m"   -- in 2 minutes
#   "+12h"  -- in 12 hours
#   "-3m"   -- 3 minutes ago(!)
sub expire_calc
# ----------------------------------------------------------
{
	my $time = shift;
	my(%unitList)=('s'=>1, 'm'=>60, 'h'=>60*60, 'D'=>60*60*24, 'M'=>60*60*24*30, 'Y'=>60*60*24*365);
	return time if (!$time || lc($time) eq 'now');
	if ( $time =~ /^(now|\d+)?([+-](?:\d+|\d*\.\d*))([smhDMY]?)/ ) { return ( ( !$1 || $1 eq 'now' ) ? time : $1 )  +$2 * $unitList{$3} }
	return $time;
}
# ----------------------------------------------------------



## bool pretty_xml(string xml)
# return xml string in a pretty view format
# arg "xml" - string xml
# return string xml
sub pretty_xml {
	my $xml_str = shift;
	my $doc = XML::LibXML->load_xml(string => $xml_str, {no_blanks => 1});
	return $doc->toString(1);

}



1;
