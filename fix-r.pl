#!/usr/bin/perl -w

########################################
#
# Automatically distribute finds on each grid when granularity of data is too high.
#
# Same as fix-f.pl just for a different grid naming schema (i.e. I12V).
#
# Author: Arjuna Del Toso (http://arjuna.deltoso.net)
#
########################################

use strict;
use warnings;

use List::MoreUtils 'pairwise';
use Text::CSV;

# WINDOWS TO UNIX
# cat -v file.csv
# tr -d '\r' < file.csv > file_unix.csv

my @alphabet = qw(I II III IV V VI VII VIII IX X XI XII XIII XIV XV);

my $csv = Text::CSV->new({ sep_char => ';', binary => 1 });

my $file = $ARGV[0] or die "Need to get CSV file on the command line\n";
open(my $data, '<:encoding(utf8)', $file) or die "Could not open '$file' $!\n";

my $num_grids =  $ARGV[1] or die "Set the number of grids.\n";
die 'Up to '.scalar @alphabet.' grids are supported' if $num_grids > scalar @alphabet;
my @grid_letters = @alphabet[0 .. $num_grids-1];

my $results = {};
my $linenum = 1;
my $header = '';
while (my $line = <$data>) {
    chomp $line;

    if ($linenum eq 1) {
	$header = $line;
	$linenum = $linenum + 1;
	next;
    }

    if ($csv->parse($line)) {
 	my @fields = $csv->fields();
	@fields = map { $_ =~ s/^$/0/g; $_ } @fields;

	my $grid = $fields[0];
	$grid =~ s/^\s+|\s+$//g;
	shift @fields;

	if ($grid =~ /^[a-zA-Z]{1}\d+[IV]+$/) {
	# Single grid item (examples: I13II or F16V)
	    &add($grid, $results, @fields);

	} else {
	# Complex grid item (examples: 127a+b+d or 56+57)
	    if ($grid =~ /^[a-zA-Z]{1}[0-9]+$/) {
		# Grid is the entire macro-grid: H13
		# Each value needs to be divided by the cardinality
		# of grids and added back to each single grid.
		my @divided_fields = ();
		foreach my $value (@fields) {
		    $value = 0 unless $value;
		    push(@divided_fields, $value/$num_grids);
		}
		foreach my $letter (@grid_letters) {
		    &add($grid.$letter, $results, @divided_fields);
		}

	    } elsif ($grid =~ /^([a-zA-Z]{1}[0-9]+)([IVX+]+)$/) {
		# Grid is multiple sub-grids: I16II+III+IV
		# Each value needs to be divided by the number of
		# sub-grids and added back to the proper sub-grids.
		my @sub_grid_letters = split /\+/, $2;
		my $divisor = scalar @sub_grid_letters || 1;
		my @divided_fields = ();
		foreach my $value (@fields) {
		    $value = 0 unless $value;
		    push(@divided_fields, $value/$divisor);
		}

		foreach my $letter (@sub_grid_letters) {
		    &add($1.$letter, $results, @divided_fields);
		}

	    } elsif ($grid =~ /^([a-zA-Z]{1}[0-9+]+)+?$/) {
		# Grid is multiple grids: H72+F43
		# Each value needs to be divided by the cardinality
		# of grids x number of grids in this entry and added
		# back to all the grids.
 		my @single_grids = split /\+/, $grid;
 		my $divisor = scalar @single_grids || 1;
		$divisor = $divisor * $num_grids;

 		my @divided_fields = ();
 		foreach my $value (@fields) {
 		    $value = 0 unless $value;
 		    push(@divided_fields, $value/$divisor);
 		}

  		foreach my $grid (@single_grids) {
		    foreach my $letter (@grid_letters) {
			&add($grid.$letter, $results, @divided_fields);
		    }
  		}

	    } else {
		# Print unexpected grid notation.
		print STDERR '>>>>> ', $grid, "\n";
	    }
	}

    } else {
	warn "Line could not be parsed: $line\n";
    }
}

# Print to STDOUT the results
print $header,"\n";
my @keys = sort { lc($a) cmp lc($b) } keys %$results;
foreach my $key (@keys) {
    print "$key;".join(';', @{$results->{$key}}),"\n";
}

sub add {
    my $grid = shift(@_);
    my $results = shift(@_);
    my @new_values = @_;

    if ($results->{$grid}) {
	# grid already in memory, add every value to current ones
	my @current_values = @{$results->{$grid}};
	no warnings qw(once);
	my @sum = pairwise { $a + $b } @current_values, @new_values;
	$results->{$grid} = \@sum;
    } else {
	# new grid, store the values
	$results->{$grid} = \@new_values;
    }
}
