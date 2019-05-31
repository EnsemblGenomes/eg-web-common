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
    say "=> Updating $ini_path/$sp.ini => $new_line";
    $new_line = quotemeta($new_line);
    my $cmd = `perl -pi -e '\$_ = qq($new_line\\n) if /(ASSEMBLY_CONVERTER_FILES.*\n)/' $ini_path/$sp.ini`;
    say $cmd;
  }
  else {
    say "=> Adding new entry $ini_path/$sp.ini => $new_line";
    $new_line = quotemeta($new_line);
    my $cmd = `perl -pi -e '\$_ .= qq(\\n$new_line\\n\\n) if /\\[general\\]/' $ini_path/$sp.ini`;
    say $cmd;
  }
}
say "\n\n\n>>>  Mistakes are common!!! Please randomly cross check and ensure updates are correct <<< \n\n\n";

