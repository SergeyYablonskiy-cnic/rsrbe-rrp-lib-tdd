## @file
# @brief creator for getters and settors methods for the CLASS

package KS::Accessor;
# *********************************************************************

use strict;
use warnings;
use utf8;

use vars qw(%attr $VERSION);

# Create accessor methods for object's fields
# the field may have two levels nesting (please use the symbol '/' as delimeter)
# a field ended to ':rw' will create as writeble
sub import
# ----------------------------------------------------------
{

	my $class = shift;
	my $package = caller(0);
	my %method2field = @_;

	while ( my($method, $field) = each %method2field ) {
		no strict "refs";
		next if defined *{$package.'::'.$method}; # the method already exist
		# rewritable method has ':rw' at the end
		my $is_rewritable = $field =~ s/:rw$//;
		my ($key1, $key2) = split m|/|, $field, 2;

		*{$package.'::'.$method} = $is_rewritable
			? $key2
				? sub {$_[0]->{$key1}{$key2} = $_[1] if exists $_[1] ; $_[0]->{$key1}{$key2}}
				: sub {$_[0]->{$key1} = $_[1] if exists $_[1] ; $_[0]->{$key1}}
			: $key2
				? sub {$_[0]->{$key1}{$key2}}
				: sub {$_[0]->{$key1}};
	}

}
# ----------------------------------------------------------


1;
