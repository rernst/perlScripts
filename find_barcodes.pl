#!usr/bin/perl -w

### Robert Ernst
### 28-11-2013
### Finds barcodes (perfect match) in fastq file and report statistics.

use strict;
use Data::Dumper;

### Command line arguments
if ($#ARGV != 1 ) {
  print "usage: $0 fastqFile barcodeFile\n";
  exit;
}

my $fastqFile = $ARGV[0];
my $barcodeFile = $ARGV[1];

### Parse barcode file
  # Name	Sequence	Orientation 
  # 1f		ACAGTATATA	Forward

open(FILE,$barcodeFile) || die("Can't open $barcodeFile");
my %forwardBarcodes;
my %reverseBarcodes;
my $header = <FILE>;

while (my $line = <FILE>) {
  chomp($line);
  my($barcodeName, $barcodeSeq, $barcodeOrientation) = split(/\t/, $line);
  if ($barcodeOrientation eq "Forward"){$forwardBarcodes{$barcodeName} = $barcodeSeq}
  elsif ($barcodeOrientation eq "Reverse"){$reverseBarcodes{$barcodeName} = $barcodeSeq}
}
close(FILE);

### Setup variables.
my $linePosition = 0;
my $countReads = 0;
my %countBarcodes;
my $read;

my %fragmentLength;
my $completeFragments = 0;

### Open fastq file
open(FILE,$fastqFile) || die("Can't open $fastqFile");

while (<FILE>) {
  $linePosition++; # counting lines
  
  if ($linePosition == 2) { # sequence is on line 2.
    $read = $_;
    chomp($read);
    
    my $keyForward = "";
    my $keyReverse = "";
    
    ### check forward key
    for my $key ( keys(%forwardBarcodes)){
      if ($read =~ m/$forwardBarcodes{$key}/){
	$keyForward = $key;
	last; #countine if barcode is found.
      }
    }
    
    ### check reverse key
    for my $key ( keys(%reverseBarcodes)){
      if ($read =~ m/$reverseBarcodes{$key}/){
	$keyReverse = $key;
	last; #countine if barcode is found.
      }
    }
    
    ### count reverse - forward key combinations
    $countBarcodes{$keyForward . $keyReverse} ++; 
    
    ### complete fragment found -> count length
    if (length($keyForward . $keyReverse) == 4){
      $read =~ m/$forwardBarcodes{$keyForward}(.*)$reverseBarcodes{$keyReverse}/;
      $fragmentLength{$keyForward . $keyReverse} += length($1);
    }
  }
  
  ### read ends on line 4 -> reset counter
  elsif ($linePosition == 4) {
    $linePosition = 0;
    $countReads++;
  }
}
close(FILE);

my $total_count = 0; #count fragments.

### Print output -> tab delim .txt file
print "Barcode \t Count (percentage) \t mean fragment length \n";
for my $key ( keys(%countBarcodes)){
    my $count = $countBarcodes{$key};
    my $percentage = $countBarcodes{$key} / $countReads * 100;
    print "$key \t";
    print "$count ($percentage) \t";
    if (length($key) == 4){
      print $fragmentLength{$key} / $count;
    }
    $total_count += $count;
    print "\n";
}
print "Total number of reads \t $countReads\n";
print "Total number of counts \t $total_count\n"; # compare with total reads -> should be equal!

