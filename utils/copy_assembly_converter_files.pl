use 5.10.1;
use strict;
use warnings;
use File::Find  qw(find);
use File::Slurp qw(read_dir);
use File::Copy  qw(copy);

# helper script to copy FASTA files for assembly converter

my $ftp_path = $ARGV[0];
my $dest_path  = $ARGV[1];

die "Usage: $0 <ftp-source-path> <ac-dest-path>\n" unless $ftp_path and $dest_path;
die "Cannot find ftp dir: $ftp_path\n" unless -d $ftp_path;
die "Cannot find dest dir: $dest_path\n" unless -d $dest_path;

my $ac_path = "$ftp_path/assembly_chain";
my @ac_dirs = sort(read_dir($ac_path));

foreach my $ac_dir (@ac_dirs) {
  next if $ac_dir =~ /_collection/;

  say "\n>>> $ac_dir";
  say `cp -rv $ac_path/$ac_dir $dest_path`; 
 
  my $copy_fasta = sub{
    return unless /$ac_dir\..*\.dna\.toplevel\.fa.gz$/i;
    say "copying fasta $File::Find::name --> $ac_path/$ac_dir";
    copy($File::Find::name, "$ac_path/$ac_dir") || die $!;
  };

  my $copy_index = sub{
    return unless /$ac_dir\..*\.dna\.toplevel\.fa.gz.fai$/i;
    say "copying index $File::Find::name --> $ac_path/$ac_dir";
    copy($File::Find::name, "$ac_path/$ac_dir") || die $!;
  };

  my $fasta_path = "$ftp_path/fasta/$ac_dir/dna";
  my $index_path = "$ftp_path/fasta/$ac_dir/dna_index";

  find($copy_fasta, $fasta_path); 
  find($copy_index, $index_path);
}