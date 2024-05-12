use strict;
use warnings;

use App::Perl::Module::Version;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = App::Perl::Module::Version->new;
isa_ok($obj, 'App::Perl::Module::Version');

# Test.
eval {
	App::Perl::Module::Version->new(
		'bad_param' => 'foo',
	);
};
is($EVAL_ERROR, "Unknown parameter 'bad_param'.\n", "Unknown parameter 'bad_param'.");
clean();
