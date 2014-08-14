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

die usage() if @ARGV == 0;
GetOptions (
	'bed=s' => \$bed_file,
	'dict=s' => \$genome_dict_file,
) or die usage();

die usage() unless $bed_file;
die usage() unless $genome_dict_file;

### Functionality
### remove "chr" from chromosomes
### sort bed file
### gatk list file
### picard bed file (header + max 5 columns)

### Functions
sub usage{
	warn <<END;
	Usage: perl bedConverter.pl -bed [file.bed] -dict [genome.dict] 
END
	exit;
}