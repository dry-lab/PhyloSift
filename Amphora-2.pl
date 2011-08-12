#!/usr/bin/env perl

use warnings;
use strict;

use FindBin qw($Bin); use lib "$Bin/lib";
use Getopt::Long;
use Amphora2::Amphora2;
use Carp;
use Amphora2::Utilities qw(debug);
use POSIX;

my $pair=0;
my $threadNum=1;
my $clean=0;
my $force=0;
my $continue=0;
my $isolate=0;
my $custom = "";
my $reverseTranslate=0;
my $besthit=0;
my $updated=0;
my $help=0;
my $usage = qq~
  Usage: $0 <mode> <options> <reads_file>                                                                       

    ~;
my $usage2 = qq~
  Usage: $0 <mode> <options> -paired <reads_file_1> <reads_file_2>                                              

    ~;

my $help_message = qq~

Amphora-2 Help.

Usage
==========================================
> perl Amphora-2.pl <Mode> <options> <sequence_file>

   sequence_file needs to be in fasta format

> perl Amphora-2.pl <Mode> <options> -paired <sequence_file_1> <sequence_file_2>

   sequence_file_1 and _2 need to be in fastq format

Mode : Only execute a specific step in the pipeline
  all - execute all the following steps in that order.
  blast - only execute the blast search + write candidate files
  align - hmmsearch + hmmalign + trims + coverage filters
  placer - run pplacer on the results from the align step
  summary - run the taxonomy assignment steps

Options Available at this time :
   -h -help             Prints the usage section of the README
   -custom <file>       Reads a custom marker list from a file otherwise use all the markers from the markers directory
   --threaded=<Number>  Runs Blast and Hmmer using the number of processors sepcified
                        Runs 1 Pplacer per processor specified
                        (DEFAULT : 1)
   -clean               Cleans the temporary files created by Amphora (NOT YET IMPLEMENTED)
   -paired              Looks for 2 input files (paired end sequencing) in FastQ format.
                        Reversing the sequences for the second file listed
                        and appending to the corresponding pair from the first file listed.
   -continue            Enables the pipeline to continue to subsequent steps when not using the 'all' mode
   -reverse             If the submitted sequences were Nucleotides, the program prints out an alignment for all the markers in DNA space in addition to the one in Protein space.
   -isolate             Use this mode if you are running data from an Isolate genome

~;

GetOptions("threaded=i" => \$threadNum,
	   "clean" => \$clean,
	   "paired" => \$pair, # used for paired fastQ input split in 2 different files                           
	   "custom=s" => \$custom, #need a file containing the marker names to use without extensions ** marker names shouldn't contain '_'
	   "f" => \$force, #overrides a previous run otherwise stop                                               
	   "continue" => \$continue, #when a mode different than all is used, continue the rest of Amphora after the section specified by the mode is finished
	   "isolate" => \$isolate, #use when processing one or more isolate genomes
	   "reverse"=> \$reverseTranslate,#use to output the reverse translation of the AA alignments
	   "besthit" => \$besthit, #should we keep only the best hit when there are multiple?
	   "updated_markers"=> \$updated, #Indicates if Amphora2 uses the updated versions of the Markers.
	   "h"=>\$help,#prints the usage part of the README file
	   "help"=>\$help,#same as -h
    )|| die $usage;

if($help != 0){
    print $help_message."\n";
    die "End of Help message\n";
}

debug( "@ARGV\n" );
if($pair ==0){
    croak $usage unless ($ARGV[0] && $ARGV[1]);
}elsif(scalar(@ARGV) == 3){
    croak $usage2 unless ($ARGV[0] && $ARGV[1] && $ARGV[2]);
}else{
    croak $usage."\nOR\n".$usage2."\n";
}


unless((POSIX::uname)[4] =~ /64/ || $^O =~ /arwin/){
	print STDERR (POSIX::uname)[4]."\n";
	die "Sorry, Amphora 2 requires a 64-bit OS to run.\n";
}

my $newObject = new Amphora2::Amphora2();
debug "PAIR : $pair\n";
if($pair == 0){
    debug "notpaired @ARGV\n";
    $newObject = $newObject->initialize($ARGV[0],$ARGV[1]);
}else{
    debug "INSIDE paired\n";
    $newObject = $newObject->initialize($ARGV[0],$ARGV[1],$ARGV[2]);
}

$newObject->{"isolate"} = $isolate;
$newObject->{"besthit"} = $besthit;
$newObject->{"reverseTranslate"} = $reverseTranslate;
$newObject->{"updated"}=$updated;

my $readsFile = $newObject->getReadsFile;
debug "FORCE: ".$force."\n";
debug "Continue : ".$continue."\n";
$newObject->run($force,$custom,$continue);

#Amphora2::Amphora2::run(@ARGV);

