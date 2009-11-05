use IRC::Client;
use JSON::Tiny;

class Mubot;

has $!irc;
has $!server;
has $!user;
has $!nick;
has @!channels;

has %.karma is rw;
has %.links is rw;

method init {
	$!irc = IRC::Client.new;
	$!irc.connect($!server);
	$!irc.user($!user);
	$!irc.nick($!nick);
	for @!channels -> $channel {
		$!irc.join($channel);
	}
	my $karma = open('karma.log', :r);
	%.karma = from-json($karma.slurp);
	$karma.close;
	my $links = open('links.log', :r);
	%.links = from-json($links.slurp);
	$links.close;
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
		self.cmd-help($params);
	} elsif $command ~~ 'karma' {
		self.cmd-karma($params);
	} elsif $command ~~ 'purge' {
		self.cmd-purge($params);
	} elsif $command ~~ 'link' {
		self.cmd-link($params);
	} elsif $command ~~ 'unlink' {
		self.cmd-unlink($params);
	} else {
		return "Sorry, I don't understand that command";
	}
}

method cmd-help(@params) {
	return "usage: $!nick: [karma [name] | purge <name> | link <nick> <alternative>] | <name>++ | <name>--";
}

method cmd-karma(@params) {
	if @params != 0 {
		my $name = @params.join(' ').trim;
		if %.karma.exists($name) {
			return "$name has a karma of " ~ %.karma<<$name>>;
		} elsif %.links.exists($name) {
			my $real = %.links<<$name>>;
			return "$real has a karma of " ~ %.karma<<$real>>;
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

method cmd-link(@params) {
	if @params < 2 {
		return "Sorry, link requires 2 parameters";
	}
	my $nick = @params.shift;
	my $alternative = @params.join(' ');
	$alternative .= subst(/ '(' || ')' /, '', :g);
	$alternative .= trim;
	if %.links.exists($alternative) {
		return "$alternative is already an alias of "~%.links<<$alternative>>;
	} elsif %.links.exists($nick) {
		return "$nick is an alias of {%.links<<$nick>>} and can not be set as a master nick";     
	} else {
		%.links.push($alternative, $nick);
	}
	if %.karma.exists($alternative) {
		%.karma<<$nick>> += %.karma<<$alternative>>;
		%.karma.delete($alternative);
		self.export-karma;
	}
	self.export-links;
	return "$alternative is now an alias for $nick ($nick will gain any karma given to $alternative)";
}

method cmd-unlink(@params) {
	if @params < 1 {
		return "Sorry, unlink requires 1 parameter";
	}
	my $nick = @params.join(' ');
	unless %.links.exists($nick) {
		return "$nick is not an alias of anyone";
	}
	my $alternative = %.links<<$nick>>;
	%.links.delete($nick);
	self.export-links;
	return "$nick is no longer an alias of $alternative";
}



method increment(Str $name is rw) {
	if %.links.exists($name) {
		$name = %.links<<$name>>;
	}
	%.karma<<$name>>++;
	self.export-karma;
}

method decrement(Str $name is rw) {
	if %.links.exists($name) {
		$name = %.links<<$name>>;
	}
	%.karma<<$name>>--;
	self.export-karma;
}

method export-karma {
	my $file = open('karma.log', :w);
	$file.print(to-json(%.karma));
	$file.close;
}

method export-links {
	my $file = open('links.log', :w);
	$file.print(to-json(%.links));
	$file.close;
}

# vim: ft=perl6
