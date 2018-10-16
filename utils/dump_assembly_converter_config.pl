use 5.10.1;
use strict;
use warnings;
use File::Find;

# helper script to udpate INI configs for assembly converter files
# remove .bak files once you are happy with the changes.
# diff command in the script shows any changes made.

my $path= $ARGV[0] || die 'Please supply assembly converter file dir';
my $ini_path = $ARGV[1] || die 'Please supply destination ini files update dir';
my $files = {};

find(sub {
  my $file = $_;
  my $dir  = [split /\//, $File::Find::dir]->[-1]; 
  push @{$files->{$dir}}, s/.chain.gz$//r if /.chain.gz$/;
}, $path);

foreach my $sp (sort keys %$files) {
  say "\n#", ucfirst $sp;
  my $new_line = sprintf 'ASSEMBLY_CONVERTER_FILES = [%s]', join(' ', sort @{$files->{$sp}});
  my $found = `grep ASSEMBLY_CONVERTER_FILES $ini_path/$sp.ini`;
  if($found) {
    my $cmd = "cp $ini_path/$sp.ini $ini_path/$sp.ini.bak";
    system($cmd);
    $cmd = "sed -e 's/ASSEMBLY_CONVERTER_FILES = .*/$new_line/' $ini_path/$sp.ini.bak > $ini_path/$sp.ini";
    system($cmd);
    $cmd = "diff $ini_path/$sp.ini.bak $ini_path/$sp.ini";
    my $out = system($cmd);
    unlink("$ini_path/$sp.ini.bak") if ($out == 0);
  }
  else {
    say "Adding new entry ";
    my $cmd = "echo >> $ini_path/$sp.ini; echo $new_line >> $ini_path/$sp.ini;";
    system($cmd);
  }
}

