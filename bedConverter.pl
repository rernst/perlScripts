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
my $sort = '';

die usage() if @ARGV == 0;
GetOptions (
	'bed=s' => \$bed_file,
	'dict=s' => \$genome_dict_file,
	'gatk' => \$gatk,
	'picard' => \$picard,
	'sort' => \$sort)
or die usage();

die usage() unless $bed_file;
die usage() unless $genome_dict_file;

### Functionality
if ($sort) {
	my $input_bed_file = $bed_file;
	$bed_file =~ s/.bed/_sorted.bed/;
	`awk '{FS=""; print "chr"\$0}' $input_bed_file |
	sed 's/chrX/chr23/g' | sed 's/chrY/chr24/g'|sed 's/chrMT/chr25/g' |
	sort -k 1.4,1n -k 2,2n -k 3,3n |
	sed 's/chr23/chrX/g' | sed 's/chr24/chrY/g' | sed 's/chr25/chrMT/g' |
	sed 's/^chr//g' > $bed_file`;
}

### gatk list file
if ($gatk) {
	my $gatk_file = $bed_file;
	$gatk_file =~ s/.bed/_gatk.list/;

	`awk {'print \$1":"\$2"-"\$3'} $bed_file > $gatk_file`
}

### picard bed file (header + max 5 columns)
if ($picard){
	my $picard_file = $bed_file;
	$picard_file =~ s/.bed/_picard.bed/;

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
