use v6;

BEGIN { @*INC.push: 'lib' }

use IRC::Client;
use Mubot;

my $mubot = Mubot.new(:server('irc.freenode.net'),
	:user('zaslon'),
	:nick('mubot'),
	:channels('#perl6'));

$mubot.init;

loop { $mubot.read; }
