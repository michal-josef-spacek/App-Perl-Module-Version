package App::Perl::Module::Version;

use strict;
use warnings;

use Class::Utils qw(set_params);
use File::Find::Rule;
use Getopt::Std;
use IO::Barf qw(barf);
use Perl6::Slurp qw(slurp);
use Readonly;

# Constants.
Readonly::Scalar our $SPACE => q{ };

our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Process parameters.
	set_params($self, @params);

	# Object.
	return $self;
}

# Run.
sub run {
	my $self = shift;

	# Process arguments.
	$self->{'_opts'} = {
		'd' => '.',
		'h' => 0,
	};
	if (! getopts('d:h', $self->{'_opts'})
		|| $self->{'_opts'}->{'h'}) {

		print STDERR "Usage: $0 [-d dir] [-h] [--version] version\n";
		print STDERR "\t-d dir\t\tDirectory to process (default is actual ".
			"directory).\n";
		print STDERR "\t-h\t\tPrint help.\n";
		print STDERR "\t--version\tPrint version.\n";
		print STDERR "\tversion\t\tNew version to set.\n";
		return 1;
	}
	my $version = $ARGV[0];

	# Old directory.
	my $old_dir = `pwd`;
	chomp $old_dir;
	chdir $self->{'_opts'}->{'d'};

	# Remove cache files.
	rmdir 'blib';
	unlink 'Makefile';
	unlink 'Makefile.old';

	# Change CHANGES.
	my $changes_file;
	if (-w 'CHANGES') {
		$changes_file = 'CHANGES';
	} elsif (-w 'Changes') {
		$changes_file = 'Changes';
	}
	if (defined $changes_file) {
		my $changes = slurp($changes_file);
		my $new_changes;
		if ($changes !~ m/^$version/ms) {
			$new_changes = $version."\n\n".$changes;
		}
		barf($changes_file, $new_changes);
	}

	# Change Makefile.PL
	if (-w 'Makefile.PL') {
		my @make = slurp('Makefile.PL', { 'chomp' => 1 });
		foreach my $make_line (@make) {
			if ($make_line =~ m/^version/) {
				$make_line = "version '$version';";
			}
			if ($make_line =~ m/['"]?VERSION['"]?\s*=>\s*/ms) {
				$make_line =~ s/(['"]?VERSION['"]?\s*=>\s*['"]?)[\d\.]+(['"]?)/$1$version$2/ms;
			}
		}
		my $make = join "\n", @make;
		$make .= "\n";
		barf('Makefile.PL', $make);
	}

	# Change META.yml.
	if (-w 'META.yml') {
		my @meta = slurp('META.yml', { 'chomp' => 1 });
		foreach my $meta_line (@meta) {
			if ($meta_line =~ m/^version:\s+/) {
				$meta_line = "version: '$version'";
			}
		}
		my $meta = join "\n", @meta;
		$meta .= "\n";
		barf('META.yml', $meta);
	}

	# Change perl modules.
	my $rule = File::Find::Rule->new;
	my @pms = $rule->or(
		$rule->new->directory->name('inc')->prune->discard,
		$rule->new->directory->name('t')->prune->discard,
		$rule->new->directory->name('blib')->prune->discard,
		$rule->new->file->name('*.pm'),
	)->in('.');
	foreach my $pm_file (@pms) {
		my @pm = slurp($pm_file, { 'chomp' => 1 });
		my $num;
		foreach my $pm_line (@pm) {
			$pm_line =~ s/^our \$VERSION = (['"]?)\d+\.\d+(['"]?);$/our \$VERSION = $1$version$2;/ms;
			if ($pm_line =~ m/^=head1 VERSION$/ms) {
				$num = 1;
			}
			if (defined $num) {
				if ($num == 3) {
					$pm_line = $version;
				}
				$num++;
			}
		}
		my $pm = join "\n", @pm;
		$pm .= "\n";
		barf($pm_file, $pm);
	}

	# Change README.
	if (-w 'README') {
		my @readme = slurp('README', { 'chomp' => 1 });
		my $num;
		foreach my $readme_line (@readme) {
			if ($readme_line =~ m/^VERSION$/ms) {
				$num = 1;
			}
			if (defined $num) {
				if ($num == 2) {
					$readme_line = ($SPACE x 4).$version;
				}
				$num++;
			}
		}
		my $readme = join "\n", @readme;
		if (@readme) {
			$readme .= "\n";
		}
		barf('README', $readme);
	}

	# Update version in bin/ scripts.
	if (-d 'bin') {
		system "perl-script-version -d bin/ $version";
	}

	# Change tests.
	system 'perl-module-tests -t';

	# Change examples.
	system 'perl-module-examples';

	# Make.
	if (-e 'Makefile.PL') {
		system 'perl Makefile.PL';
	}

	# Back to old dir.
	chdir $old_dir;
	
	return 0;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Perl::Module::Version - Base class for perl-module-version tool.

=head1 SYNOPSIS

 use App::Perl::Module::Version;

 my $app = App::Perl::Module::Version->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::Perl::Module::Version->new;

Constructor.

Returns instance of object.

=head2 C<run>

 my $exit_code = $app->run;

Run.

Returns 1 for error, 0 for success.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE

=for comment filename=print_help.pl

 use strict;
 use warnings;

 use App::Perl::Module::Version;

 # Arguments.
 @ARGV = (
         '-h',
 );

 # Run.
 exit App::Perl::Module::Version->new->run;

 # Output like:
 # Usage: ./print_help.pl [-d dir] [-h] [--version]
 #         -d              Debug mode.
 #         -d dir          Directory to process (default is actual directory).
 #         -h              Print help.
 #         --version       Print version.
 #         version         New version to set.

=head1 DEPENDENCIES

L<Class::Utils>,
L<File::Find::Rule>,
L<Getopt::Std>,
L<IO::Barf>,
L<Perl6::Slurp>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-Perl-Module-Version>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2012-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
