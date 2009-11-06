use v6;

BEGIN { @*INC.push: 'lib' }

use JSON::Tiny;

if @*ARGS < 1 {
	die "usage: perl6 $*PROGRAM_NAME lamdabot-data.log\n" ~
	"lambdabot-data.log is the file created by lambdabot-extractor.pl\n";
}

my $file = open(@*ARGS[0], :r);

# for $file.lines { ... } causes a segfault
my $data = $file.slurp;

my @pairs = $data.split("\n");

my %karma = {};

for @pairs {
	my ($who, $karma) = $_.split('=');
	%karma.push: $who, $karma;
}

my $karma-file = open('karma.log.lambda', :w);
$karma-file.print(to-json(%karma));

say "karma.log.lambda has been created.
Rename that file to karma.log to have mubot use it";
