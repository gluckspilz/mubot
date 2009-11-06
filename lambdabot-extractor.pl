use v6;

BEGIN { @*INC.push: 'lib' }

use IRC::Client;

my $irc = IRC::Client.new;

$irc.connect('irc.freenode.net');

$irc.user('zaslon');
$irc.nick('mubotimporter');
$irc.privmsg('lambdabot', '@karma-all');

loop {
	my $msg = $irc.receive;
	say $msg;
	if $msg ~~ / ':' .*? ':' '[' (.*?) '@more lines' ']' / {
		$irc.privmsg('lambdabot', '@more');
	} elsif $msg ~~ / ':' .*? ':' <ws> '"'(.*?)'"' \s+ (<digit>*) .* / {
		my $log = open('lambdabot-data.log', :a);
		$log.print("{$0.Str}={$1.Str}\n");
		$log.close;
	}
}

