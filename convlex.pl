#!/usr/bin/perl

# sort|uniq input!

use warnings;
use strict;
use utf8;

binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");

my %seen = ();

# Sphinx uses case-insensitive phones

my %phn = (
	'I' => 'y',
        'Z' => 'rz',
	'dZ' => 'drz',
	'tS' => 'cz',
	'S' => 'sz'
);
sub phone {
	my $ph = shift;
	if(exists $phn{$ph}) {
		return uc($phn{$ph});
	} else {
		return uc($ph);
	}
}

while(<>) {
	chomp;
	my @parts = split/[ \t]/;
	next if($#parts == 0);
        my $l = shift @parts;
	my @phones = map { phone($_) } @parts;
	my $r = join(" ", @phones);
	if(exists $seen{$l}) {
		print "$l($seen{$l}) $r\n";
		$seen{$l}++;
	} else {
		print "$l $r\n";
		$seen{$l} = 1;
	}
}
