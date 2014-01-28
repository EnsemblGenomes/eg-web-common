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

# Name:        drupal_fetch_species_content.pl --url=http://dev.ensemblgenomes.org/export/ensembl-species/plants --plugin_root=eg-plugins/plants
# Author:      Jay Humphrey jhumphre@ebi.ac.uk EnsemblGenomes Web Team
# Description: read a list of files and output TSV for importing them to Drupal site ensemblgenomes.org
# Parameters:
#   --url:  the URI of the xml feed
#   --plugin_root: download destination directory, e.g. eg-plugins/plants)

package EG::Drupal::Fetch::Species;

use strict;
use warnings;

use Getopt::Long;
use LWP::Simple qw/get getstore/;
use URI;
use URI::Escape;
use XML::Simple;
use HTML::Entities;
use File::Basename;
use Cwd qw/cwd/;
use File::Path qw/remove_tree make_path/;
use Image::Magick;
use Data::Dumper;

exit main();

sub main {
  my ($url, $plugin_root, $noimg, $tmp);
  GetOptions('url=s' => \$url, 'plugin_root=s' => \$plugin_root, 'noimg' => \$noimg, 'tmp=s');
  die "No plugin_root provided. Use some directory containing 'htdocs' such as --plugin_root=eg-plugins/plants\n" unless $plugin_root;
  $tmp ||= "/tmp";
  my $aboutdir = "$plugin_root/htdocs/ssi/species";
  my $imgdir64 = "$plugin_root/htdocs/i/species/64";
  my $imgdir48 = "$plugin_root/htdocs/i/species/48";
  make_path($imgdir64) unless (-d $imgdir64);
  make_path($imgdir48) unless (-d $imgdir48);
  make_path($aboutdir) unless (-d $aboutdir);
  my $urlparse = URI->new($url);
  my ($host,$hostpath) = ($urlparse->host,$urlparse->path);
  printf ("Fetching %s ...\n", $url);
  my $xmldoc = get($url) or die "Fetch $url failed: $!\n";
  my $xml = XMLin($xmldoc);
  my @fields = qw/about assembly annotation regulation variation other references/;
  foreach my $species (keys %{$xml->{'node'}}){
    my $file = sprintf('%s/about_%s.html',$aboutdir,ucfirst($species));
    open(FH,">$file") or die ("Cannot write $file:$!\n");
    printf STDERR ("Writing $file\n");
    foreach my $field (@fields){
      next if(ref($xml->{'node'}->{$species}->{$field}) eq 'HASH');
      printf FH ("<!-- {%s} -->\n%s\n<!-- {%s} -->\n",$field, $xml->{'node'}->{$species}->{$field} || "",$field);
    }
    close FH;
    my ($imgurl) = $xml->{'node'}->{$species}->{'image'} =~ /^.*src=['"]([^'^"]+)['"]/;
    printf STDERR ("Fetching %s\n", $imgurl);
    
    make_path($tmp) unless (-d $tmp);
    my $tmpimg = sprintf ('%s/%s.png',$tmp,ucfirst($species));
    getstore($imgurl,$tmpimg);
    my $image = new Image::Magick;
    $image->Read($tmpimg);
    $image->Resize(width=>64, height=>64);
    my $x = $image->Write(filename=>sprintf("%s/%s.png",$imgdir64,ucfirst($species)));
    warn $x if $x;
    printf STDERR ("Writing %s/%s.png\n",$imgdir64,ucfirst($species));
    $image->Resize(width=>48, height=>48);
    $image->Write(sprintf("%s/%s.png",$imgdir48,ucfirst($species)));
    printf STDERR ("Writing %s/%s.png\n",$imgdir48,ucfirst($species));
    unlink $tmpimg;
  }
  return 0;
}
1;
