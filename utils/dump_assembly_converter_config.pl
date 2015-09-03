use 5.10.1;
use strict;
use warnings;
use File::Find;

# helper script to dump INI configs for assembly converter files 

my $path  = $ARGV[0] || die 'Please supply assembly converter file dir';
my $files = {};

find(sub {
  my $file = $_;
  my $dir  = [split /\//, $File::Find::dir]->[-1]; 
  push @{$files->{$dir}}, s/.chain.gz$//r if /.chain.gz$/;
}, $path);

foreach my $sp (sort keys %$files) {
  say "\n#", ucfirst $sp;
  say sprintf 'ASSEMBLY_CONVERTER_FILES = [%s]', join(' ', sort @{$files->{$sp}});
} 



