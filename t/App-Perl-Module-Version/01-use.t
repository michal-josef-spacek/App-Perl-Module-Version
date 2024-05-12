use strict;
use warnings;

use Test::More 'tests' => 3;
use Test::NoWarnings;

BEGIN {

	# Test.
	use_ok('App::Perl::Module::Version');
}

# Test.
require_ok('App::Perl::Module::Version');
