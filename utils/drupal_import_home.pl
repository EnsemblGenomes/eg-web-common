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

# Name:        drupal_import_home.pl --url=http://dev.ensemblgenomes.org/export/ensembl-home --plugin_root=eg-web-plants
# Author:      Jay Humphrey jhumphre@ebi.ac.uk EnsemblGenomes Web Team
# Description: read a list of files and output TSV for importing them to Drupal site ensemblgenomes.org
# Parameters:
#   --root: the top of the Ensembl installation, eg /nfs/public/rw/ensembl/ensembl-genome/current/plants/
#   --url:  the URI of the xml feed
#   --plugin_root: download destination directory, e.g. eg-web-plants)
#   --noimg: do not download images

package EG::Drupal::Fetch::Home;

use strict;
use warnings;

use Getopt::Long;
use URI;
use URI::Escape;
use LWP::Simple qw/get getstore/;
use XML::Simple;
use HTML::Entities;
use File::Basename;
use File::Path qw/make_path/;
use Cwd qw/cwd/;

use FindBin qw($Bin);
chdir "$Bin/../..";

exit EG::Drupal::Fetch::Home::main();

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self, $class);
  return $self;
}

sub main {
 #my $obj = EG::Drupal->new;
  my ($root, $url, $plugin_root, $noimg, $division, $release, $quiet, $commit, $message);
#  $plugin_root = "my-plugins";

  GetOptions('root=s' => \$root, 'd|division=s' => \$division, 'r|release=s' => \$release, 'url=s' => \$url, 'plugin_root=s' => \$plugin_root, 'noimg' => \$noimg, 'q' => \$quiet, 'c|commit=s' => \$commit, 'm|message=s' => \$message);
  if($root){
    chdir($root) or die "Cannot use $root: $!\n";
    printf STDERR ("In %s\n", cwd()) unless $quiet;
  }
  unless($division && $release){
    my $cwd = cwd();
    my $parent;
    ($division,$parent)=fileparse($cwd);
    ($release) = $parent =~ m/([0-9]+)\/?$/;
  }
  $division = lc($division) if $division;
  if($division && $release){
    $plugin_root ||= "eg-web-$division";
    $url ||= sprintf("http://www.ensemblgenomes.org/export/ensembl-home/%s/%s",$division,$release);
  }
  if(!$url){die "please specify division (-d plants) AND release (-r 20), or -url\n";}
  my $file_path = "$plugin_root/htdocs/ssi";
  my $index_path = "$plugin_root/htdocs/index.html";
  my $image_path = "$plugin_root/htdocs/img";
  make_path("$file_path") unless -d $file_path;
  make_path("$image_path") unless -d $image_path;
  my @commits = ($file_path,$image_path);
  
  my $urlparse = URI->new($url);
  my ($host,$hostpath) = ($urlparse->host,$urlparse->path);
  $hostpath =~ tr/\//./;
  printf ("Fetching %s ...\n", $url);
  my $xmldoc = get($url) or die "Fetch $url failed: $!\n";
  my $xml = XMLin($xmldoc);
  my $node = $xml->{'node'};
  if($node->{'layout'}){
    printf STDERR ("Writing $index_path\n") unless $quiet;
    open (OUTFILE, "+>", $index_path) or die "$!\n";
    print OUTFILE ($node->{'layout'});
    close OUTFILE;
    delete $node->{'layout'};
    system("cvs add $index_path") if $commit;
    push(@commits,$index_path);
  }
  elsif ( -e $index_path ){
    unlink($index_path);
    system("cvs rm $index_path") if $commit;
  }
  
  foreach my $field ( keys %$node ){
    next unless($node->{$field});
    my $dest = sprintf("%s/%s.inc",$file_path,$field);
    unlink($dest);
    next if(ref($node->{$field}) eq 'HASH');
    $node->{$field} = sprintf('<div class="plain-box">%s</div>',$node->{$field});
    $node->{$field} =~ s/<p>\s*<\/p>//smg;
    $node->{$field} =~ s/(\s+)(<\/[^>]*>)/$2$1/smg; #shift trailing spaces outside of tags
    unless ($noimg){
    # download images to prefix (e.g. my-plugins/htdocs/), stripping mask from the file path
      my @images = $node->{$field} =~ m/src=["']{1}[\/]?([^"^']+)["']{1}/g;
      if(@images){
        foreach my $img (@images){
          my $basename=basename($img);
          my $image_file = sprintf('%s/%s',$image_path,$basename);
          my $dirname = dirname($image_file);
          make_path($dirname) unless (-d $dirname);
          printf STDERR ("Downloading $host/$img, save to $image_file...\n") unless $quiet;
          getstore("http://$host/$img", $image_file);
          warn "$host/$img was not downloaded to $image_file!\n" unless -e $image_file;
          next unless (-e $image_file);
          push(@commits,$dirname);
          system(sprintf('cvs add %s', $image_file)) if $commit;
          # now fix the path in the file
          $image_file =~ s/^.+htdocs//;
          $node->{$field} =~ s/src=["']{1}[\/]?$img["']{1}/src="$image_file"/;
        }
      }
    }
  # printf STDERR ("Images %s\n", Dumper(\@images)); 
    printf STDERR ("Writing: %s\tlength %d\n", $dest,length($node->{$field})) unless $quiet;
    open (OUTFILE, "+>", $dest) or die "$!\n";
    $node->{$field} =~ s/[^[:ascii:]]+//g;
    print OUTFILE ($node->{$field});
    close OUTFILE;
    system("cvs add $dest") if $commit;
  }
  if($commit){
    printf STDERR ("Committing: %s\n", join(" ", @commits)) unless $quiet;
    $commit = sprintf(':ext:%s@cvs.sanger.ac.uk:/cvsroot/CVSmaster',$commit);
    system(sprintf(qq{cvs -d %s commit -m "%s" %s}, $commit, $message, join(" ", @commits)));
  }
  return 0;
}

1;

