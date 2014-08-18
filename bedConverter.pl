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

die usage() if @ARGV == 0;
GetOptions (
	'bed=s' => \$bed_file,
	'dict=s' => \$genome_dict_file,
	'gatk' => \$gatk,
	'picard' => \$picard)
or die usage();

die usage() unless $bed_file;
die usage() unless $genome_dict_file;

### Functionality
### remove "chr" from chromosomes ???
### sort ???

### gatk list file
if ($gatk) {
	my $gatk_file = $bed_file;
	$gatk_file =~ s/.bed/_gatk.list/;

	print "\n $gatk_file \n";
	`awk {'print \$1":"\$2"-"\$3'} $bed_file > $gatk_file`
}

### picard bed file (header + max 5 columns)
if ($picard){
	my $picard_file = $bed_file;
	$picard_file =~ s/.bed/_picard.bed/;

	print "\n $picard_file \n";
	`cat $genome_dict_file > $picard_file`;
	`awk -v OFS='\t' {'print \$1,\$2,\$3,\$4,\$5'} $bed_file >> $picard_file`;
}

### Functions
sub usage{
	warn <<END;
	Usage: perl bedConverter.pl -bed <file.bed> -dict <genome.dict> [-gatk -picard]
END
	exit;
}
