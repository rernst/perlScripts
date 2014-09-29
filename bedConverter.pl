#!usr/bin/perl
### Robert Ernst
### 14-08-2014
### Reads a bed file and convert to gatk, picard and/or igv format.

use strict;
use warnings;
use Getopt::Long;

### Parse and check input arguments
my $bed_file;
my $genome_dict_file;
my $gatk = '';
my $picard = '';
my $picard_strand_col;
my $picard_interval_name_col;
my $sort = '';

die usage() if @ARGV == 0;
GetOptions (
	'bed=s' => \$bed_file,
	'dict=s' => \$genome_dict_file,
	'gatk' => \$gatk,
	'picard' => \$picard,
	'strand_column=i' => \$picard_strand_col,
	'interval_name_column=i' => \$picard_interval_name_col,
	'sort' => \$sort)
or die usage();

### Usage checks and feedback
die usage() unless $bed_file;
die usage() unless $genome_dict_file;

if ($picard) {
    print "WARNING:\tStrand column not provided asuming + strand.\n" unless $picard_strand_col;
    print "WARNING:\tInterval column not provided using chr:start-end as interval name.\n" unless $picard_interval_name_col;
}

### Functionality
if ($sort) {
	my $input_bed_file = $bed_file;
	$bed_file =~ s/.bed/_sorted.bed/;
	
	`awk '{FS=""; print "chr"\$0}' $input_bed_file |
	sed 's/chrX/chr23/g' | sed 's/chrY/chr24/g'|sed 's/chrMT/chr25/g' |
	sort -k 1V -k 2n -k 3n |
	sed 's/chr23/chrX/g' | sed 's/chr24/chrY/g' | sed 's/chr25/chrMT/g' |
	sed 's/^chr//g' > $bed_file`;
}

if ($gatk || $picard) {

    if ($gatk) {
	my $gatk_file = $bed_file;
	$gatk_file =~ s/.bed/_gatk.list/;
	open(GATKFILE, '>', $gatk_file) || die("Can't open $bed_file")
    }
    
    if ($picard) {
	my $picard_file = $bed_file;
	$picard_file =~ s/.bed/_picard.bed/;
	`cat $genome_dict_file > $picard_file`;
	open(PICARDFILE, '>>',  $picard_file) || die("Can't open $bed_file")
    }

    open(FILE,$bed_file) || die("Can't open $bed_file");
    while (my $line = <FILE>) {
	chomp($line);
	my @splitted_line = split('\t',$line);
	
	my $chr = $splitted_line[0];
	my $start= $splitted_line[1];
	my $end = $splitted_line[2];
	
	if ($gatk) {
	    print GATKFILE "$chr:$start-$end\n";
	}
	
	if ($picard) {
	    my $strand;
	    my $interval_name;

	    if ($picard_strand_col) {
		$strand = $splitted_line[$picard_strand_col];
	    } else {
		$strand = "+";
	    }

	    if ($picard_interval_name_col) {
		$interval_name = $splitted_line[$picard_interval_name_col];
	    } else {
		$interval_name = "$chr:$start-$end";
	    }

	    print PICARDFILE "$chr\t$start\t$end\t$strand\t$interval_name\n";
	}
    }
}

### Functions
sub usage{
	warn <<END;
	Usage: perl bedConverter.pl -bed <file.bed> -dict <genome.dict> [-sort] [-gatk] [-picard -strand_column <strand column number> -interval_name_column <interval name column number>]
END
	exit;
}
