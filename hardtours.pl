#!/usr/bin/perl
use LWP::Simple;
use Encode;
use Term::ANSIColor;

use strict;
no warnings "experimental::postderef", "experimental::signatures";

my $date_regex = '(^[0-9\.\-\s]+)';
my $BASE_URL = 'https://www.hardtours.de';
my $ticker;

_init();

my $input;
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
	my @found_keys = ();
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
		my $color = get_color($ticker->{$found}->{occupied});
		print ++$i.". \'".colored($found,$color)."\' davon sind ". colored($ticker->{$found}->{occupied},$color)." belegt.";
		print "Findet am ".$ticker->{$found}->{date}." statt." if($ticker->{$found}->{date});
		print "(".colored($ticker->{$found}->{url},'bold blue').")" if $ticker->{$found}->{url};
		print "\n";
	}
} 


sub _init {
	print "Loading festivals from ".$BASE_URL." ...\n";
	load_festivals();
	die "Could not find any festivals :-(" unless((keys %{$ticker}));
	print "Successfully loaded the festivals![".(keys %{$ticker})." found]\n";
	print "=" x 50, "\n";
}

sub load_festivals {
	my $contents = Encode::encode_utf8(get($BASE_URL));
	die "Could not fetch ".$BASE_URL.", please check your connection!\n" unless($contents);
	my @tours;
	if($contents =~ /<div class=\"tickerRow\">([^\?]+)/ ) {
		$contents = $1;
		$contents =~ s/<script[\s\S]+//g;
		$contents = trim($contents);
		@tours = split(/<li>/,$contents);
	}
	foreach my $tour (@tours) {
		next unless($tour =~ /tour/);
		if($tour =~ /<b>([^<]+)/) {
			my $name = $1;
			my $date;
			my $tour_url;
			if($name =~ /$date_regex/) {
				$date = $1 unless($1 =~ /^\s*$/);
				$name =~ s/$date_regex//;
			}
			if($tour =~ /href=\"([^\"]+)/) {
				$tour_url = $BASE_URL.$1;
			}
			$name = trim($name);
			$date = trim($date);
			if($tour =~ /tickerNumber\'>([^<]+)/) {
				$ticker->{$name} = {
					date => $date,
					occupied => $1 // "0%",
				};
				$ticker->{$name}->{url} = $tour_url if($tour_url); 
			}
		}
	}
}

sub print_help {
	print "#" x 50;
	print "\nHier alle aktuellen Kommandos:\n";
	print "exit   : Beende das Programm\n";
	print "reload : Aktualisiere die Daten\n";
	print "all    : Zeige alle Festivals an\n";
	print "Beschreibung der Color-Codes:\n";
	print colored("Fast alle Tickets noch da!(<= 25%)",get_color(25)),"\n";
	print colored("Weniger als die Hälfte ausverkauft!(<= 50%)",get_color(50)),"\n";
	print colored("Mehr als die Hälfte ausverlkauft!(<= 75%)",get_color(75)),"\n";
	print colored("Nur noch wenige Tickets zu haben!(>75%)",get_color(100)),"\n";
	print "#" x 50;
	print "\n";
}

sub get_color {
	my $occ = shift;
	$occ =~ s/%//g;
	return 'bold cyan' if $occ <= 25;
	return 'bold green' if $occ <= 50;
	return 'bold yellow' if $occ <= 75;
	return 'bold red';
}

sub trim {
	my $arg = shift;
	$arg =~ s/^\s+|\s+$//g;
	return $arg;
}