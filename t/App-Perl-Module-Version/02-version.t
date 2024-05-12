use strict;
use warnings;

use App::Perl::Module::Version;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::Perl::Module::Version::VERSION, 0.01, 'Version.');
