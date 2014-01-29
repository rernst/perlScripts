#!usr/bin/perl
use strict;
use warnings;
use List::Util qw(first);
use Getopt::Long;

### Parse and check input arguments
my $pedFile;
my $vcfFile;

die usage() if @ARGV == 0;
GetOptions (
	'ped=s' => \$pedFile,
	'vcf=s' => \$vcfFile
) or die usage();

die usage() unless $pedFile;
die usage() unless $vcfFile;

### Setup global variables
my %samples;
my %samplesIndex;
my %childNonRefCount;
my %disconcordantNonRefCount;

my %childRefCount;
my %disconcordantRefCount;


### Parse Ped File:
# 	familyID	sampleID	fatherID	motherID	Sex	Phenotype
open(FILE, $pedFile) || die("Can't open $pedFile");

while (my $line = <FILE>) {
	chomp($line);
	my($familyID, $sampleID, $fatherID, $motherID, $sex, $phenotype) = split(/\t/, $line);
	if ($fatherID || $motherID) { #both not 0 so child.
		$samples{$sampleID} = {"fatherID" => $fatherID, "motherID" => $motherID } ; 
	}
}

### Parse VCF File:
if ($vcfFile =~ m/.gz$/){ open(FILE, "bgzip -c -d $vcfFile |") || die("Can't open $vcfFile"); }
elsif ($vcfFile =~ m/.vcf$/){ open(FILE, $vcfFile) || die("Can't open $vcfFile"); }
else { die usage(); }

while (my $line = <FILE>) {
	if ($line =~ /^##/) { next; } #skip header lines
	
	# Parse column names
	elsif ($line =~/^#/) { 
		chomp($line);
		my @header = split("\t", $line);
		foreach my $childID (keys(%samples)) {
			my $fatherID = $samples{$childID}{"fatherID"};
			my $motherID = $samples{$childID}{"motherID"};
			
			my $childIndex = first { $header[$_] eq $childID } 0..$#header;
			my $fatherIndex = first { $header[$_] eq $fatherID } 0..$#header;
			my $motherIndex = first { $header[$_] eq $motherID } 0..$#header;
			
			$samplesIndex{$childID} = $childIndex;
			$samplesIndex{$fatherID} = $fatherIndex;
			$samplesIndex{$motherID} = $motherIndex;
			
			$childNonRefCount{$childID} = 0;
			$childRefCount{$childID} = 0;
			$disconcordantNonRefCount{$childID} = 0;
			$disconcordantRefCount{$childID} = 0;

		}
	}
	# Parse variant lines
	else {
		chomp($line);
		my @vcfLine = split("\t", $line);
		
		if (uc($vcfLine[6]) ne "PASS") { next; } #Skip filtered calls
		
		elsif (length($vcfLine[3]) > 1 || length($vcfLine[4]) > 1) { next; } #Skip indel calls
		
		elsif (uc($vcfLine[0]) eq "X" || uc($vcfLine[0]) eq "Y") { next; } #Skip x and y chromosome 
		
		foreach my $childID (keys(%samples)) {
			my $fatherID = $samples{$childID}{"fatherID"};
			my $motherID = $samples{$childID}{"motherID"};

			my $childIndex = $samplesIndex{$childID};
			my $fatherIndex = $samplesIndex{$fatherID}; 
			my $motherIndex = $samplesIndex{$motherID};

			my $childCall = (split(":", $vcfLine[$childIndex]))[0];
			my $fatherCall = (split(":", $vcfLine[$fatherIndex]))[0];
			my $motherCall = (split(":", $vcfLine[$motherIndex]))[0];

			if ($childCall eq "0/0") {
				$childRefCount{$childID} ++;
				if ($fatherCall eq "1/1" || $motherCall eq "1/1") {
					$disconcordantRefCount{$childID} ++;
				}
				next;
			}
			
			elsif ($childCall eq "1/1") { 
				$childNonRefCount{$childID} ++;
				if ($fatherCall eq "0/0" || $motherCall eq "0/0") {
					$disconcordantNonRefCount{$childID} ++;
				}
			}

			elsif ($childCall eq "0/1") { 
				$childNonRefCount{$childID} ++;
				if ($fatherCall eq "0/0" && $motherCall eq "0/0") {
					$disconcordantNonRefCount{$childID} ++;
				}
				elsif ($fatherCall eq "1/1" && $motherCall eq "1/1") {
					$disconcordantNonRefCount{$childID} ++;
				}
			}
		}
	}
}

### Print the result
print "ChildID \t ChildNonRefCounts \t disconcordantNonRefCounts \t percentageDisconcordantNonRef \t ChildRefCounts \t disconcordantRefCounts \t percentageDisconcordantRef \t totalChildCount \t totalDisconcordantCounts \t percentageDisconcordant \n";
foreach my $childID (keys(%samples)) {
	my $percentageNonRefDisconcordant = $disconcordantNonRefCount{$childID} / $childNonRefCount{$childID} * 100;
	my $percentageRefDisconcordant = $disconcordantRefCount{$childID} / $childRefCount{$childID} * 100;
	
	my $totalChildCount = $childNonRefCount{$childID} + $childRefCount{$childID};
	my $totalDisconcordantCount = $disconcordantNonRefCount{$childID} + $disconcordantRefCount{$childID};
	my $percentageDisconcordant = $totalDisconcordantCount / $totalChildCount * 100;
	
	print $childID ."\t"; 
	
	print $childNonRefCount{$childID} ."\t"; 
	print $disconcordantNonRefCount{$childID} ."\t";
	print $percentageNonRefDisconcordant ."\t";
	
	print $childRefCount{$childID} ."\t";
	print $disconcordantRefCount{$childID} ."\t";
	print $percentageRefDisconcordant ."\t";
	
	print $totalChildCount ."\t";
	print $totalDisconcordantCount ."\t";
	print $percentageDisconcordant ."\n";
}

### Functions
sub usage{
	warn <<END;
	Usage:	perl trioConcordance.pl -ped [pedFile] -vcf [vcfFile.vcf | vcfFile.gz]
END
	exit;
}