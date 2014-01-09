#!usr/bin/perl
### Robert Ernst
### 09-01-2014
### Reads a FASTQ file and splits it into several fastq files, based on barcode matching (perfect match).
### Outputs reads to fastq files
### Statistics will be printed to STDOUT

use strict;
use warnings;

### Command line arguments
if ($#ARGV != 2 ) {
  print "usage: $0 fastqFile barcodeFile sampleFile\n";
  exit;
}
my $fastqFile = $ARGV[0];
my $barcodeFile = $ARGV[1];
my $sampleFile = $ARGV[2];

### Parse barcode file
  # Name	Sequence	Orientation 
  # 1f		ACAGTATATA	Forward
my %forwardBarcodes;
my %reverseBarcodes;

open(FILE,$barcodeFile) || die("Can't open $barcodeFile");
my $header = <FILE>;
while (my $line = <FILE>) {
  chomp($line);
  my($barcodeName, $barcodeSeq, $barcodeOrientation) = split(/\t/, $line);
  if ($barcodeOrientation eq "Forward"){$forwardBarcodes{$barcodeName} = $barcodeSeq}
  elsif ($barcodeOrientation eq "Reverse"){$reverseBarcodes{$barcodeName} = $barcodeSeq}
}
close(FILE);

### Parse Sample file
  # BarcodeCombination SampleName
  # 1F1R	Sample_1
my %samples;
open(FILE,$sampleFile) || die("Can't open $sampleFile"); 
$header = <FILE>; 
while (my $line = <FILE>) {
  chomp($line);
  my ($barcodeCom, $sampleName) = split(/\t/, $line);
  $samples{$barcodeCom} = $sampleName;
}
close(FILE);

### Prepare fastq output files
# create output dir if not exist.
unless(-e "fastqOut" or mkdir "fastqOut") {
  die "Unable to create output directory";
}

# create fastq file for each sample.
my %files;
foreach my $sample (keys(%samples)) {
  my $file;
  my $fileName = $sample ."_". $samples{$sample};
  open($file,">","fastqOut/$fileName.fastq");
  $files{$sample} = $file;
}

### Setup variables.
my $readLinePosition;
my $countReads;
my %countBarcodes;
my $read;

my %fragmentLength;
my $fragment;
my $fragment_start;
my $fragment_end;
my $quality;
my $complete;
my $completeFragments;
my $sample;

my $readLine1;
my $readLine3;

### Open fastq file
open(FILE,$fastqFile) || die("Can't open $fastqFile");

while (<FILE>) {
  $readLinePosition++; # counting lines
  
  if ($readLinePosition == 1) { $readLine1 = $_; } #save first line of read
    
  elsif ($readLinePosition == 2) { # sequence is on line 2.
    $read = $_;
    chomp($read);
    
    my $keyForward = "";
    my $keyReverse = "";
    
    ### check forward barcode
    for my $key ( keys(%forwardBarcodes)){
      if ($read =~ m/$forwardBarcodes{$key}/){
	$keyForward = $key;
	last; #continue if forward barcode is found.
      }
    }
    
    ### check reverse barcode
    for my $key ( keys(%reverseBarcodes)){
      if ($read =~ m/$reverseBarcodes{$key}/){
	$keyReverse = $key;
	last; #continue if reverse barcode is found.
      }
    }
    
    ### count barcode combinations
    $countBarcodes{$keyForward . $keyReverse} ++; 
    
    ### complete fragment found
      # count length
      # select fragment
    if (($keyForward ne "") && ($keyReverse ne "")) {  
    #if (length($keyForward . $keyReverse) > 3){
      $read =~ m/$forwardBarcodes{$keyForward}(.*)$reverseBarcodes{$keyReverse}/; #find fragment
      if (length($1)) {
	$fragmentLength{$keyForward . $keyReverse} += length($1);
	
	$fragment = $1; #save fragment
	$fragment_start = $-[1]; #save fragment start position
	$fragment_end = $+[1]-$-[1]; #save fragment end position
	
	$sample = $keyForward . $keyReverse;
	$complete = 1;
	$keyForward = "";
	$keyReverse = "";
      }
    }
  }
  
  elsif ($readLinePosition == 3) { $readLine3 = $_; } #save third line of read
  
  ### read ends on line 4
    # if complete print read to correct fastq file
  elsif ($readLinePosition == 4) {
    $countReads++;
    $readLinePosition = 0;
    if ($complete == 1){
      $quality = $_;
      chomp($quality);
      $quality = substr($quality, $fragment_start, $fragment_end);    
      my $file = $files{$sample};
      print $file "$readLine1$fragment\n$readLine3$quality\n";
      $complete = 0;
    }
  }
}
close(FILE);

### Print statistics -> tab delim .txt file
print "Barcode \t SampleName \t Count \t Percentage \t Mean fragment length \n";
for my $key ( keys(%countBarcodes)){
    my $count = $countBarcodes{$key};
    my $percentage = $countBarcodes{$key} / $countReads * 100;
    print "$key\t";
    if ($samples{$key}) { print "$samples{$key}\t" ; } else { print "No sample \t"; }
    print "$count \t $percentage \t";
    if ($samples{$key}) { print $fragmentLength{$key} / $count; } else { print "No sample"; }
    print "\n";
}
print "Total number of reads \t $countReads\n";