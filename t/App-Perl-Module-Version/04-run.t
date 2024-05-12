use strict;
use warnings;

use App::Perl::Module::Version;
use English;
use File::Object;
use File::Spec::Functions qw(abs2rel);
use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Output;

# Test.
@ARGV = (
	'-h',
);
my $script = abs2rel(File::Object->new->file('04-run.t')->s);
# XXX Hack for missing abs2rel on Windows.
if ($OSNAME eq 'MSWin32') {
	$script =~ s/\\/\//msg;
}
my $right_ret = <<"END";
Usage: $script [-d dir] [-h] [--version] version
	-d dir		Directory to process (default is actual directory).
	-h		Print help.
	--version	Print version.
	version		New version to set.
END
stderr_is(
	sub {
		App::Perl::Module::Version->new->run;
		return;
	},
	$right_ret,
	'Run help.',
);
