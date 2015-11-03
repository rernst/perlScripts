#! /usr/bin/perl

use strict;

my $fastq_file_1 = shift;
die "First argument must be a fastq file" unless $fastq_file_1;

my $fastq_file_2 = shift;
die "Seccond argument must be a fastq file" unless $fastq_file_2;

open(FASTQ1, "gunzip -c $fastq_file_1 |") || die "can't open pipe to $fastq_file_2";

my %fastq_1_seq = ();
my %fastq_1_qual = ();
my $count = 0; #0 = header 1=seq 2=+ 3=qual
my $header;
my $key;
my $seq;
my $qual;

my $seq_error = 0;
my $qual_error = 0;
my $total = 0;

print "Parsing: $fastq_file_1 \n";

while(<FASTQ1>){
    if($count == 0){
	$header = $_;
	($key) = split(" ",$_,2);
    }
    elsif($count == 1){
	$seq = $_;
    }
    elsif($count == 3){
	$qual = $_;
	$count = 0;
	$fastq_1_seq{$key} = $seq;
	$fastq_1_qual{$key} = $qual;
	next;
    }
    $count ++;
}

print "Comparing $fastq_file_1 and $fastq_file_2\n";

open(FASTQ2, "gunzip -c $fastq_file_2 |") || die "can't open pipe to $fastq_file_2";
while(<FASTQ2>){
    if($count == 0){
	$header = $_;
	($key) = split("/",$_,2);
    }
    elsif($count == 1){
	$seq = $_;
    }
    elsif($count == 3){
	$qual = $_;
	$count = 0;
	if($fastq_1_seq{$key} ne $seq){
	    $seq_error ++;
	}
	print $key ."\n";
	print $fastq_1_seq{$key}."\n";
	print $seq."\n\n\n";
	if($fastq_1_qual{$key} ne $qual){
	    $qual_error ++;
	}
	$total ++;
	next;
    }
    $count ++;
}

print "Compared $total sequences \n";
print "Total seq Errors : $seq_error\n";
print "Total quality Errors : $qual_error\n\n";
