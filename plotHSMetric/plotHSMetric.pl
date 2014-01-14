#!/usr/bin/perl
### Plot HSMetric
#   13-01-2013

use warnings;
use strict;

### Setup variables
my $fileName = "HSMetric_summary.txt";
open(SUMFILE, ">", $fileName) || die ("Can't open if $fileName");
my @files = grep -f, <*/*HSMetrics\.txt>;
my $printedHeader = 0;

### Generate metric summary
foreach my $file (@files) {
    print "Working on: ". $file . "\n";
    open(FILE, $file) || die ("Can't open $file");
    my $baitIntervals;
    my $targetIntervals;
    
    #Processing headerlines -> beginning with # or " ".
    while(<FILE> =~ /(^\s*#)(.*)/ || <FILE> eq "") {
        my $headerLine = $2;
        if ($headerLine =~ m/BAIT_INTERVALS=(\S*).TARGET_INTERVALS=(\S*)/){
            $baitIntervals = $1;
            $targetIntervals = $2;
		}
	}
    
   #Processing table
    my $tableHeader =  <FILE>;
    unless ($printedHeader) { 
        print SUMFILE "sample \t sampleShort \t baitIntervals \t targetIntervals \t". $tableHeader;
        $printedHeader = 1;
    }
    
    my $line = <FILE>;
    my $sample = (split("/",$file))[0];
    my $sampleShort = (split("_",$file))[0];
    print SUMFILE $sample ."\t". $sampleShort ."\t". $baitIntervals ."\t". $targetIntervals ."\t". $line;
}

### Run R plot script and markdown to generate pdf
`Rscript plotHSMetric.R $fileName`;