#!/usr/bin/env perl
# Copyright [2009-2014] EMBL-European Bioinformatics Institute
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Name:        drupal_import_species.pl --url=http://www.ensemblgenomes.org/export/ensembl-species/plants --plugin_root=eg-web-plants
# Author:      Jay Humphrey jhumphre@ebi.ac.uk EnsemblGenomes Web Team
# Description: read a list of files and output TSV for importing them to Drupal site ensemblgenomes.org

use strict;
use warnings;

use Getopt::Long;
use LWP::Simple qw/get getstore/;
use URI::Find;
use Encode;
use XML::Simple;
use HTML::Entities;
use File::Basename;
use File::Copy;
use File::Path qw/make_path/;
use Imager;
use Try::Tiny;

use FindBin qw($Bin);
chdir "$Bin/../..";

my $num_errors = 0; 
my $tmp = '/tmp';

my ($plugin_root, $noimg, $division, $quiet, $pan, $needs_rename);
my $host = 'http://www.ensemblgenomes.org';

GetOptions(
  'd|division=s'  => \$division, 
  'plugin_root=s' => \$plugin_root, 
  'noimg'         => \$noimg, 
  'q'             => \$quiet, 
  'pan'           => \$pan,
  'host=s'        => \$host,
  'needs_rename'     => \$needs_rename,  
);

die "please specify division (e.g. -d plants)" unless $division;

$plugin_root ||= "eg-web-$division";

if ($pan) {
  `mkdir -p ${plugin_root}/htdocs/ssi/species`;
  getstore("$host/export/ensembl-pan-species", "${plugin_root}/htdocs/ssi/species/pan_compara_species.xml");
  exit;
}

my $url         = "$host/export/ensembl-species/$division";
my $aboutdir    = "$plugin_root/htdocs/ssi/species";
my $imgdir64    = "$plugin_root/htdocs/i/species/64";
my $imgdir48    = "$plugin_root/htdocs/i/species/48";
my $imgdir32    = "$plugin_root/htdocs/i/species/32";
my $imgdir16    = "$plugin_root/htdocs/i/species/16";
my $img_dir_large = "$plugin_root/htdocs/i/species/large";
my $default_img = "$plugin_root/htdocs/i/default_species_large.png";
my $image_path  = "$plugin_root/htdocs/img";

$default_img = undef unless -e $default_img;

make_dir($aboutdir, $imgdir64, $imgdir48, $imgdir32, $imgdir16, $img_dir_large, $image_path);

printf STDERR ("Fetching %s ...\n", $url) unless $quiet;
my $xmldoc = get($url) or die "Fetch $url failed: $!\n";

my $xml = XMLin(encode('utf-8', $xmldoc));
my @fields = qw/acknowledgement about assembly annotation regulation variation other/;
foreach my $species (sort keys %{$xml->{'node'}}) {
  my $Species = ucfirst($species);
  my $node = $xml->{'node'};
  
  my $file = "$aboutdir/about_$Species.html";
  open(FH, ">$file") or die("Cannot write $file:$!\n");
  binmode(FH, ":utf8");
  
  info("Writing $file");

  foreach my $field (@fields) {
    next unless ($node->{$species}->{$field});
    # $node->{$species}->{$field} =~ s/<p>\s*<\/p>//smg;
    # $node->{$species}->{$field} =~ s/&nbsp;/ /smg;
    unless ($noimg) {
      # download images to prefix (e.g. my-plugins/htdocs/), stripping mask from the file path
      my @images = $node->{$species}->{$field} =~ m/src=["']{1}[\/]?([^"^']+)["']{1}/g;
      if (@images) {
        foreach my $img (@images) {
          
          my $image_file = sprintf '%s/%s', $image_path, basename($img);
          make_dir(dirname($image_file));
          info("Downloading $host/$img, save to $image_file");
          getstore("$host/$img", $image_file);
          info("$host/$img was not downloaded to $image_file!") unless -e $image_file;

          # now fix the path in the file
          $image_file =~ s/^.+htdocs//;
          $node->{$species}->{$field} =~ s/src=["']{1}[^"^']*$img["']{1}/src="$image_file"/smg;
        }
      }
    }
    printf FH ("<!-- {%s} --><a name=\"%s\"></a>\n%s\n<!-- {%s} -->\n", $field, $field, $node->{$species}->{$field} || "", $field);
  }

  my $pubsurl = "$host/$node->{$species}->{'pubs'}";
  my $pubsxml = get($pubsurl);
  $pubsxml =~ s/[^[:ascii:]]//g;
  my $pubs = XMLin(encode('utf-8', $pubsxml));
  my @publist;
  if (defined($pubs->{'node'})) {
    if (ref($pubs->{'node'}) eq 'HASH') {$pubs->{'node'} = [$pubs->{'node'}];}
    my $refnum = 1;
    foreach my $pub (@{$pubs->{'node'}}) {
      my $html  = '';
      my $title = $pub->{'title'};
      $title =~ s/\s*\.\s*$//;
      if    ($pub->{'url'})  {$title = sprintf('<a href="%s">%s</a>',                                   $pub->{'url'},  $title);}
      elsif ($pub->{'PMID'}) {$title = sprintf('<a href="http://europepmc.org/abstract/MED/%s">%s</a>', $pub->{'PMID'}, $title);}
      elsif ($pub->{'DOI'})  {$title = sprintf('<a href="http://dx.doi.org/%s">%s</a>',                 $pub->{'DOI'},  $title);}
      else {    # linkify urls in title
        my $finder = URI::Find->new(sub {my ($uri, $orig_url) = @_; return qq{<a href="$url">$orig_url</a>};});
        $finder->find(\$title);
      }
      my $authors = $pub->{'authors'} || $pub->{'author'};
      my @authlist = split(/,/, $authors);
      if (@authlist > 10) {
        $authors = join(',', @authlist[0 .. 9]);    # We print the first 10 authors + et al.
        $authors .= " et al";
      }
      $html .= "$title.<br>";
      $html .= sprintf("%s. ", $authors) if ($authors);
      $html .= sprintf("%s. ", $pub->{'year'}) if ($pub->{'year'});
      $html .= sprintf("%s. ", $pub->{'journal'}) if ($pub->{'journal'});
      $html .= sprintf("%s", $pub->{'volume'}) if ($pub->{'volume'});
      if ($pub->{'pages'}) {$html .= sprintf(":%s.", $pub->{'pages'});}
      push(@publist, sprintf('<li><a id="ref-%02d"></a>%s</li>', $refnum, $html));
      $refnum++;
    }
    if (@publist) {
      printf FH ("<h3>References</h3><ol>%s</ol>", join("\n", @publist));
    }
    printf FH ("<p>%s</p>", $node->{$species}->{'image_credit'}) if ($node->{$species}->{'image_credit'});
  }
  close FH;

  my $tmpimg   = "$tmp/$Species.png";
  my ($imgurl) = $node->{$species}->{'image'} =~ /^.*src=['"]([^'^"]+)['"]/;

  if ($imgurl) {  
    info("Fetching $imgurl");
    getstore($imgurl, $tmpimg);
  }

  if(!$imgurl or !-e $tmpimg) {
    if($default_img) {
      info("Using default species image");
      copy ($default_img, $tmpimg);
    } else {
      warn "ERROR: no image and no default!\n";
    }
  } 

  my $img_read = 0;
  my $image = Imager->new();
  unless(-e $tmpimg) {
    warn "ERROR: Could not find '$tmpimg', skipping\n";
    next;
  }
  try {
     $image->read(file => $tmpimg, png_ignore_benign_errors => 1) or die;
     $img_read = 1;
  } catch {
     warn "png_ignore_benign_errors flag does not work ($tmpimg). Going to ignore it";
    try {
     $image->read(file => $tmpimg) or die "Cannot read: ", $image->errstr;
    } catch {
      warn "ERROR: Cannot read: ", $image->errstr;
      $num_errors++;
    }
  };

  save_largeimage($image,"$img_dir_large/$Species.png");
  save_thumbnail($image, "$imgdir64/$Species.png", 64);
  save_thumbnail($image, "$imgdir48/$Species.png", 48);
  save_thumbnail($image, "$imgdir32/$Species.png", 32);
  save_thumbnail($image, "$imgdir16/$Species.png", 16);

  unlink $tmpimg;
}

rename_pre_archive($aboutdir, $imgdir64, $imgdir48, $imgdir32, $imgdir16, $img_dir_large) if defined $needs_rename;

die "Dying due to earlier errors" if $num_errors;

sub rename_pre_archive {
    my @dirs = @_;
    foreach my $directory (@dirs) {
     info("------------------------");
     opendir(DIR, $directory) or die "Cannot open directory";
     foreach my $file_name (grep {/^.*_(pre|archive)\.(html|png)$/} readdir(DIR)) {
       (my $new_file_name = $file_name) =~ s/(^.*)_(pre|archive)\.(html|png)$/$1\.$3/;
#       warn $file_name;
#       warn $new_file_name;
        info("Renaming $directory/$file_name to $directory/$new_file_name");
        rename("$directory/$file_name", "$directory/$new_file_name") or print "Error renaming $file_name to $new_file_name: $!\n";
     }
      closedir(DIR);
    }
}


sub make_dir {
  my @dirs = @_;
  for (@dirs) {
    make_path($_) unless -d $_;
  }
}

sub info {
  return if $quiet;
  my $message = shift;
  warn "$message\n";
}

sub save_largeimage {
  my ($image, $filename) = @_;
  info("Writing $filename");
  
  my $large;
  
  if($image->getwidth() > 700 || $image->getheight() > 700){
    $large = $image->scale(xpixels => 700, ypixels => 700, type=>'min');
  } else {
    $large = $image->copy();
  }

  if ($large) {
    $large->write(file => $filename);
  } else {
    info("*** Failed to create image for $filename ***");
  }
}

sub save_thumbnail {
  my ($image, $filename, $size) = @_;
  info("Writing $filename");
  my $thumb = $image->scale(xpixels => $size, ypixels => $size);
  if ($thumb) {
     $thumb = $thumb->crop(right => $size, bottom => $size);
     $thumb->write(file => $filename);
  } else {
    info("*** Failed to create image for $filename ***");
  }
}

1;
