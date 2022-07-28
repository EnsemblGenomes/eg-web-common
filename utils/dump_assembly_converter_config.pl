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
my @all_ini_files;

# Get all available ini files and remove ASSEMBLY_CONVERTER_FILES entry
find(sub {
  my $file = $_;
  my $dir  = [split /\//, $File::Find::dir]->[-1];
  push @all_ini_files, $_;
}, $ini_path);

my $count = 0;
foreach my $ini (@all_ini_files) {
  next if ($ini eq '.');
  my $cmd = "grep ASSEMBLY_CONVERTER_FILES $ini_path/$ini";
  my $found = `$cmd`;
  if ($found) {
    print "Deleting -- $ini\n";
    my $del = `sed -i '/ASSEMBLY_CONVERTER_FILES/d' $ini_path/$ini`;
    $count++;
  }
}
print "\nUpdated $count files\n";


# Now get all the chain files available and add entries to corresponding species ini file.
find(sub {
  my $file = $_;
  my $dir  = [split /\//, $File::Find::dir]->[-1]; 
  push @{$files->{$dir}}, s/.chain.gz$//r if /.chain.gz$/;
}, $path);

foreach my $sp (sort keys %$files) {
  say "\n#", ucfirst $sp;
  my $new_line = sprintf 'ASSEMBLY_CONVERTER_FILES = [%s]', join(' ', sort @{$files->{$sp}});
  say "=> Adding new entry $ini_path/$sp.ini => $new_line";
  $new_line = quotemeta($new_line);
  my $cmd = `perl -pi -e '\$_ .= qq(\\n$new_line\\n) if /\\[general\\]/' $ini_path/$sp.ini`;
  print $cmd;
}

say "\n\n\n>>>  Mistakes are common!!! Please randomly cross check (or git diff) and ensure updates are correct <<< \n\n\n";

