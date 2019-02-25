#! /usr/bin/env perl

# Update the drupals in this checkout per SOP.

use strict;
use warnings;

use File::Copy;
use File::Path;
use FindBin qw($Bin);
use Storable;

my $error = 0;

my $conf = retrieve("$Bin/../../config.sconf");

my $division = $conf->{'SiteDefs'}{'DIVISION'};
warn "copying generated files for $division\n";

my $dest = "$Bin/../..";
( my $src = $dest ) =~ s!/live/!/staging/!;
$src =~ s!/www_(\d+)/!/!;
my $rel = $1;

my @PARTS = (
  ["$src/eg-web-$division/htdocs/ssi/species/",'about\*'],
  ["$src/eg-web-$division/htdocs/img",'region\*'],
  ["$src/eg-web-$division/htdocs","taxon_tree_data.js"],
  ["$src/eg-web-$division","taxon_tree.packed"],
);

my (@FILES,%DIRS);
foreach my $part (@PARTS) {
  my ($dir,$pat) = @$part;
  for(split('\n',qx(find $dir -name $pat -type f))) {
    chomp;
    push @FILES,$_;
    (my $dir = $_) =~ s!/[^/]+$!!;
    $DIRS{$dir} = 1;
  }
}

foreach my $f (@FILES) {
  my $src = $f;
  my $dst = $src;
  $dst =~ s!/staging/!/live/!;
  $dst =~ s!/$division/!/$division/www_$rel/!;
  (my $dir = $dst) =~ s!/[^/]+$!!;
  unless($DIRS{$dir}) {
    warn "mkdir '$dir'\n";
    mkpath($dir);
    $DIRS{$dir} = 1;
  }
  if(!copy($src,$dst)) {
    warn "ERROR! Could not copy $src to $dst: $!\n";
    $error = 1;
  }
  print "$src -> $dst\n";
}

exit $error;

1;

