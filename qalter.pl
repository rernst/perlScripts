#! /usr/bin/perl
### Robert Ernst
### Initial code from: Mark van Roosmalen
### Alters the Queue of jobs with a certain prefix

use strict;

### User input
my $queue = shift;
my $prefix = shift;

die "No queue" unless $queue;
die "No prefix" unless $prefix;

my $qstat = `qstat | grep "$prefix"`;

my @jobs = split(/\n/, $qstat);
my @ids = map { (split(/\s+/, $_))[0] } @jobs;
my $ids = join(" ", @ids);

#print "qalter -q $queue $ids \n";
system "qalter -q $queue $ids";
