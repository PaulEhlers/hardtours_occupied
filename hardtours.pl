#!/usr/bin/perl
use LWP::Simple;
use Encode;

my $date_regex = '(^[0-9\.\-\s]+)';
my $ticker;

_init();

my $input;
my @found_keys = ();
print "Schreibe deinen Festivalnamen oder \"help\" für Hilfe(Mit \"exit\" beendest du das Skript!)\n";

while(1) {
	print "Eingabe: ";
	$input = <STDIN>;
	$input =~ s/\n//g;
	exit if ($input eq "exit");
	if($input eq "reload") {
		_init();
		next;
	}
	if($input eq "help") {
		print_help();
		next;
	}
	@found_keys = ();
	foreach my $key (keys %{$ticker}) {
		push (@found_keys,$key) if($key =~ /\Q$input\E/i || $input eq "all");
	}
	unless(scalar(@found_keys)) {
		print "Keine Festivals für die Beschreibung \"$input\" gefunden :-(\n";
		next;
	}

	print "Folgende Festivals gefunden:\n";
	my $i = 0;
	foreach my $found (@found_keys) {
		print ++$i.". \'".$found."\' davon sind ".$ticker->{$found}->{occupied}." belegt.";
		print "Findet am ".$ticker->{$found}->{date}." statt." if($ticker->{$found}->{date});
		print "\n";
	}
} 


sub _init {
	print "Loading festivals from www.hardtours.de ...\n";
	load_festivals();
	die "Could not find any festivals :-(" if((keys %{ticker}));
	print "Successfully loaded the festivals![".(keys %{$ticker})." found]\n";
	print "=" x 50, "\n";
}

sub load_festivals {
	my @tours;
	my $contents = Encode::encode_utf8(get("https://www.hardtours.de"));
	die "Could not fetch hardtours.de, please check your connection!\n" unless($contents);
	if($contents =~ /<div class=\"tickerRow\">([^\?]+)/ ) {
		$contents = $1;
		$contents =~ s/<script[\s\S]+//g;
		$contents = trim($contents);
		@tours = split(/<li>/,$contents);
	}
	foreach my $tour (@tours) {
		next unless($tour =~ /tour/);
		$bool = 0;
		if($tour =~ /<b>([^<]+)/) {
			my $name = $1;
			my $date;
			if($name =~ /$date_regex/) {
				$date = $1 unless($1 =~ /^\s*$/);
				$name =~ s/$date_regex//;
			}
			$name = trim($name);
			$date = trim($date);
			if($tour =~ /tickerNumber\'>([^<]+)/) {
				$ticker->{$name} = {
					date => $date,
					occupied => $1,
				}; 
			}
		}
	}
}

sub print_help {
	print "#" x 50;
	print "\nHier alle aktuellen Kommandos:\n";
	print "exit   : Beende das Programm\n";
	print "reload : Aktualisiere die Daten\n";
	print "#" x 50;
	print "\n";
}

sub trim {
	my $arg = shift;
	$arg =~ s/^\s+|\s+$//g;
	return $arg;
}