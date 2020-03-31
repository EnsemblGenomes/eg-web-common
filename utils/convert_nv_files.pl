#! /usr/local/bin/perl

## A script to process non-vertebrate (Ensembl Genomes) species static content
## into Markdown files

## Each input file will be split into three output files:
# <species>_description.md, <species>_annotation.md, <species>_references.md

use strict;
use warnings;

use Getopt::Long;
use Cwd qw(cwd);
use File::Path qw(make_path);

## Select which division to process

my ($division, $in_dir, $out_dir, $tmp_dir);

BEGIN{
  &GetOptions(
    'in_dir'      => \$in_dir,
    'out_dir'     => \$out_dir,
    'tmp_dir'     => \$tmp_dir,
    'division=s'  => \$division,
  );
}

my $cwd = cwd;
$in_dir  ||= "$cwd/input/$division/species";
$out_dir ||= "$cwd/output/$division/species";
$tmp_dir ||= "$cwd/tmp/$division/species"; ## Temporary directory for munged HTML

make_path($out_dir) unless (-e $out_dir);
make_path($tmp_dir) unless (-e $tmp_dir);

## Read each "about_<species>" HTML file

opendir my $dh, $in_dir or die "Could not open directory '$in_dir': $!\n";
print "Outputting temporary HTML files to $tmp_dir...\n";

my @input = readdir $dh;

foreach my $file (@input) {

  next unless $file =~ /\.html$/;

  ## Identify the species name based on the file name
  (my $species = $file) =~ s/\.html$//;
  $species =~ s/about_//;
  (my $name = $species) =~ s/_/ /;

  ## Open input file
  open my $fh, sprintf('%s/%s', $in_dir, $file) or die "Could not open file '$file' for reading: $!\n";

  my (%sections, $section);

  ## Go through the input file line by line

  while (my $line = <$fh>) {

    chomp $line;

    if ($line =~ /--><a name="(\w+)"/) {
      $section = $1;
    }
    elsif ($line =~ /h3>References/) {
      $section = 'references';
    }

    ## Skip lines that start with comments (this should also remove empty <a> tags)
    next if $line =~ /^<!/;

    ## Replace Drupal nbsp with ordinary space
    $line =~ s/<\!\-\-nbsp\-\->/ /g;

    $sections{$section} .= "$line\n"

  }

  ## Now write out each section to a file
  while (my($key, $content) = each (%sections)) {
    next unless $content;

    open(my $out_file, '>', sprintf('%s/%s_%s.html', $tmp_dir, $species, $key));
    print $out_file $content;
    close $out_file;
  }

  close $fh;
}

## Now run pandoc over the tmp directory to convert to Markdown
## We can do this one at a time as there are only a few hundred
## (and it makes the script easier to debug!)

opendir my $md, $tmp_dir or die "Could not open directory '$tmp_dir': $!\n";
print "Outputting Markdown files to $out_dir...\n";

my @tmp_files = readdir $md;

foreach my $file (@tmp_files) {

  next unless $file =~ /\.html$/;

  my $input_path  = sprintf '%s/%s', $tmp_dir, $file;
  next unless (-s $input_path); # skip empty files - not that there should be any

  (my $name = $file) =~ s/\.html$//;
  my $output_path = sprintf '%s/%s.md', $out_dir, $name;

  my $cmd = qq(pandoc $input_path -f html -t markdown -s -o $output_path);

  system($cmd);

}

## Clean up tmp files
system("rm -r $tmp_dir");

print "DONE!\n\n";
