use 5.10.1;
use strict;
use warnings;
use File::Find  qw(find);
use File::Slurp qw(read_dir);
use File::Copy  qw(copy);
use File::Path  qw(make_path);
use Data::Dumper;

# helper script to copy VEP and FASTA files for VEP tool

my $vep_path   = $ARGV[0]; # source dir for VEP cache tars 
my $fasta_path = $ARGV[1]; # source dir for fasta (all divisions)
my $dest_path  = $ARGV[2]; 

die "Usage: $0 <source-vep-path> <source-fasta-path> <dest-path>\n" unless $vep_path and $fasta_path and $dest_path;

die "Cannot find vep dir: $vep_path\n"     unless -d $vep_path;
die "Cannot find fasta dir: $fasta_path\n" unless -d $fasta_path;

if (!-d $dest_path) {
  make_path($dest_path) || die $!;
  say "Created dest path $dest_path";
}

say "Finding fasta files...";

my @fasta_files;
find(sub{
  push(@fasta_files, $File::Find::name) if /\.dna\.toplevel\.fa\.gz$/;
}, $fasta_path);

say "Finding vep files...";

my @vep_files;
find(sub{
  push(@vep_files, $File::Find::name) if /\.tar\.gz$/;
}, $vep_path);

say "Extracting and copying files...";
    
foreach my $vep_file (@vep_files) {
  my $genome = $vep_file =~ s/^.*\/(.+)_vep_.*$/$1/r;#/
  say "\n$genome";

  # extract vep
  my $tar = "tar -zx --directory $dest_path --file $vep_file";
  say $tar;
  system $tar;
  
  # copy fasta
  my $genome_path    = "$dest_path/$genome";
  my ($assembly_dir) = read_dir($genome_path); # assumes only one assembly dir per genome, may need to revisit
  my ($fasta_file)   = grep {/${genome}\./i} @fasta_files; 
  my $assembly_path  = "$genome_path/$assembly_dir";
  say "copying $fasta_file --> $assembly_path";
  copy($fasta_file, $assembly_path) || die $!;
  print `gunzip -v $assembly_path/*.fa.gz`;
}
