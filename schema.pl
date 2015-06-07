#!/usr/bin/perl -w

########################################
#
# Create ArcGIS schema.ini file from csv.
#
# Automatically create ArcGIS schema.ini files from the header of a CSV[";"] file.
# The first column is considered to be the grid (Text) and everything else the count 
# of pieces (Double).
#
# Author: Arjuna Del Toso (http://arjuna.deltoso.net)
#
# Example:
# $ head -n 1 example.csv
# grid;stones;bones;coins
# $ ./schema.pl example.csv
# [example.csv]
# Col1=grid Text
# Col2=stones Double
# Col3=bones Double
# Col4=coins Double
#
########################################

use strict;
use warnings;

use Text::CSV;

# WINDOWS
# cat -v file_grezzo.csv
# tr -d '\r' < file_grezzo.csv > file_grezzo_mac.csv

my $csv = Text::CSV->new({ sep_char => ';', binary => 1 });

my $file = $ARGV[0] or die "Need to get CSV file on the command line\n";
open(my $data, '<:encoding(utf8)', $file) or die "Could not open '$file' $!\n";

print '['.$file.']', "\n";

my $linenum = 0;
while (my $line = <$data>) {
    chomp $line;

    $linenum = $linenum + 1;
    if ($linenum eq 1) {
	if ($csv->parse($line)) {
	    my @cols = $csv->fields();
	    print 'Col1='.$cols[0].' Text', "\n";
	    my $col_num = 2;
	    shift @cols;
	    foreach my $col (@cols) {
		if ($col) {
		    print 'Col'.$col_num.'='.$col.' Double', "\n";
		    $col_num = $col_num + 1;
		}
	    }
	} else {
	    warn "Line could not be parsed: $line\n";
	}

    }
}
