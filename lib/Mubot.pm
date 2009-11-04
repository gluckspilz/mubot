use IRC::Simple;
use JSON::Tiny;

class Mubot;

has $!irc;
has $!server;
has $!user;
has $!nick;
has @!channels;
has %.karma is rw;

method init {
	$!irc = IRC::Simple.new;
	$!irc.connect($!server);
	$!irc.user($!user);
	$!irc.nick($!nick);
	for @!channels -> $channel {
		$!irc.join($channel);
	}
	my $file = open('karma.log', :r);
	%.karma = from-json($file.slurp);
	$file.close;
}

method read {
	my $msg = $!irc.receive;
	say $msg;
	if my $d = $!irc.highlight($!nick, $msg) {
		my $reply = self.parse($d<msg>);
		$!irc.privmsg($d<channel>, $reply);
		# XXX FIXME: these could probably be tidied up
	} elsif $msg ~~ / [ <wb> (\w*?) '++' 		# foo++
			| '(' <wb> (.*?) ')' '++'	# (foo bar)++
	       		| '++' (\w*) <wb>		# ++foo
			| '++' '(' (.*?) ')' ] / {	# ++(foo bar)
		self.increment($0.Str);
	} elsif $msg ~~ / [ <wb> (\w*?) '--'		# foo--
			| '(' <wb> (.*?) ')' '--'	# (foo bar)--
	       		| '--' (\w*) <wb>		# --foo
			| '--' '(' (.*?) ')' ] / {	# --(foo bar)
		self.decrement($0.Str);
	}	
}

method parse(Str $message is rw) {
	$message .= split(' ');
	my $command = $message.shift;
	my $params = $message;
	if $command ~~ 'help' {
		self.cmd-karma($params);
	} elsif $command ~~ 'karma' {
		self.cmd-karma($params);
	} elsif $command ~~ 'purge' {
		self.cmd-purge($params);
	} else {
		return "Sorry, I don't understand that command";
	}
}

method cmd-help(@params) {
	return "usage: karma [name] | purge <name>";
}

method cmd-karma(@params) {
	if @params != 0 {
		my $name = @params.join(' ').trim;
		if %.karma.exists($name) {
			return "$name has a karma of " ~ %.karma<<$name>>;
		} else {
			return "$name is of an unknown quantity";
		}
	} else {
		# XXX FIXME: want to list the top 10 highest values
		my $toplist = '';
		my $i = 0;
		for %.karma.sort.reverse {
			$toplist ~= "{.key}: {.value} | ";
			$i++;
			last if $i > 10;
		}
		return $toplist;
	}
}

method cmd-purge(@params) {
	if @params < 1 {
		return "Sorry, purge requires 1 parameter";
	}
	my $who = @params.join(' ');
	%.karma.delete($who);
	self.export-karma;
	return "$who\'s karma has been reset";
}

method increment(Str $name) {
	%.karma<<$name>>++;
	self.export-karma;
}

method decrement(Str $name) {
	%.karma<<$name>>--;
	self.export-karma;
}

method export-karma {
	my $file = open('karma.log', :w);
	$file.print(to-json(%.karma));
	$file.close;
}

# vim: ft=perl6
