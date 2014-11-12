#!/usr/bin/env perl
use warnings;
use strict;

our ($opt_h, $opt_f);
use Getopt::Std;
$Getopt::Std::STANDARD_HELP_VERSION = 1;

$main::VERSION = 0.01;

sub HELP_MESSAGE {
    print "convert.pl [-hf] <main_file> <ref_file>\n";
    print "\t-h\t\tThis help message\n";
    print "\t-f <file>\tFile containing reference numbers to pmids\n";
}

getopts("hf:");
if(defined $opt_h) {
  HELP_MESSAGE();
  exit 1;
}

# open up the text file and make ref tags for all of the
# cited references using the pmid of the article as the name
my %references;
my $text;
if (! defined $opt_f) {
  open($text, '<', $ARGV[0]) || die $!;
  while(my $line = <$text>) {
    while($line =~ /\((\d+([,-]\d+)*)\)/g) {
      my $refs = $1;
      my @reflist = split(/,/, $refs);
      foreach my $refnum (@reflist) {
        if($refnum =~ /(\d+)-(\d+)/) {
          # we have a range
          my $numstart = $1;
          my $numend = $2;
          foreach ($1..$2) {
            $references{$_} = undef;
          }
        } else {
          $references{$refnum} = undef;
        }
      }
    }
  }
  close $text;

  # open up the references file and make a hash
  open(my $references, '<', $ARGV[1]) || die $!;
  while(my $line = <$references>) {
    if ($line =~ /(\d+)\..+?\)(.*?)\./) {
      my $tid = $1;
      my $title = $2;
      if (exists $references{$tid}) {
        open(my $pipe, "esearch -db pubmed -query '$title' | efetch -mode xml | xtract -element PMID |") or die $!;
        while (my $pipeline = <$pipe>) {
          my ($match, $waste) = split(/\s+/,$pipeline,2);
          $references{$tid} = $match;
          last;
        }
      }
    }
  }
  open(my $out, '>', 'ref2pmid.txt') || die $!;
  while (my ($k,$v) = each %references) {
    print $out "$k\t".$v."\n";
  }
  close $out;
} else {
  open(my $r2p, '<', $opt_f) || die $!;
  while (<$r2p>) {
    chomp;
    my ($ref, $pmid) = split(/\t/);
    $references{$ref} = $pmid;
  }
  close $r2p;
}

open($text, '<', $ARGV[0]) || die $!;
while(my $line = <$text>) {
  my @fields = split(/(\(\d+[,-:digit:]*\))/, $line);
  foreach my $field (@fields) {
    warn $field,"\n";
    if ($field =~ /\((\d+([,-]\d+)*)\)/) {
      my $refs = $1;
      my @reflist = split(/,/, $refs);
      foreach my $refnum (@reflist) {
        if($refnum =~ /(\d+)-(\d+)/) {
          # we have a range
          my $numstart = $1;
          my $numend = $2;
          foreach ($1..$2) {
            print '<ref name="pmid'.$references{$_}.'">{{Cite pmid|'.$references{$_}.'}}</ref>';
          }
        } else {
          print '<ref name="pmid'.$references{$refnum}.'">{{Cite pmid|'.$references{$refnum}.'}}</ref>';
        }
      }
    } else {
      print $field;
    }
  }
}
close $text;
