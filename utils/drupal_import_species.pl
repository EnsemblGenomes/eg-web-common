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

# Name:        drupal_fetch_species_content.pl --url=http://www.ensemblgenomes.org/export/ensembl-species/plants --plugin_root=eg-web-plants
# Author:      Jay Humphrey jhumphre@ebi.ac.uk EnsemblGenomes Web Team
# Description: read a list of files and output TSV for importing them to Drupal site ensemblgenomes.org
# Parameters:
#   --url:  the URI of the xml feed
#   --plugin_root: download destination directory, e.g. eg-web-plants)

package EG::Drupal::Fetch::Species;

use strict;
use warnings;

use Getopt::Long;
use LWP::Simple qw/get getstore/;
use URI;
use URI::Escape;
use URI::Find;
use Encode;
use XML::Simple;
use HTML::Entities;
use File::Basename;
use Cwd qw/cwd/;
use File::Path qw/remove_tree make_path/;
use Imager;
use Bio::TreeIO;

exit main();

sub new {
  my $class = shift;
  my $self  = {};
  bless $self, $class;
  return $self;
}

sub main {
  my $self=shift;
  my ($url, $plugin_root, $noimg, $tmp, $division, $quiet, $commit, $message, $pan);
  GetOptions('url=s' => \$url, 'd|division=s' => \$division, 'plugin_root=s' => \$plugin_root, 'noimg' => \$noimg, 'tmp=s', 'q' => \$quiet, 'c|commit=s' => \$commit, 'm|message=s' => \$message, 'pan' => \$pan);
#  $plugin_root = "../eg-web-$division";
  if($pan){
    `mkdir -p ${plugin_root}/htdocs/ssi/species`;
    getstore("http://www.ensemblgenomes.org/export/ensembl-pan-species","${plugin_root}/htdocs/ssi/species/pan_compara_species.xml");
    exit;
  }
  unless($division){
    my $cwd = cwd();
    ($division)=fileparse($cwd);
  }
  if($division){
    $plugin_root ||= "eg-web-$division";
    $url ||= sprintf("http://www.ensemblgenomes.org/export/ensembl-species/%s",$division);
  }
  if(!$url){die "please specify division (-d plants), or -url\n";}
  $tmp ||= "/tmp";
  my $aboutdir = "$plugin_root/htdocs/ssi/species";
  my $imgdir64 = "$plugin_root/htdocs/i/species/64";
  my $imgdir48 = "$plugin_root/htdocs/i/species/48";
  my $imgdir16 = "$plugin_root/htdocs/i/species/16";
  my $image_path = "$plugin_root/htdocs/img";
  my @commits = ($aboutdir,$imgdir64,$imgdir48,$image_path);
  make_path($imgdir64) unless (-d $imgdir64);
  make_path($imgdir48) unless (-d $imgdir48);
  make_path($imgdir16) unless (-d $imgdir16);
  make_path($aboutdir) unless (-d $aboutdir);
  make_path("$image_path") unless -d $image_path;
  my $urlparse = URI->new($url);
  my ($host,$hostpath) = ($urlparse->host,$urlparse->path);
  printf STDERR ("Fetching %s ...\n", $url) unless $quiet;
  my $xmldoc = get($url) or die "Fetch $url failed: $!\n";
# $xmldoc =~ s/[^[:ascii:]]//g;
  my $xml = XMLin($xmldoc);
  my @fields = qw/acknowledgement about assembly annotation regulation variation other/;
  foreach my $species (keys %{$xml->{'node'}}){
    my $node = $xml->{'node'};
    my $file = sprintf('%s/about_%s.html',$aboutdir,ucfirst($species));
    open(FH,">$file") or die ("Cannot write $file:$!\n");
    binmode(FH, ":utf8");
    printf STDERR ("Writing $file\n") unless $quiet;
    foreach my $field (@fields){
      next unless ($node->{$species}->{$field});
    # $node->{$species}->{$field} =~ s/<p>\s*<\/p>//smg;
    # $node->{$species}->{$field} =~ s/&nbsp;/ /smg;
      unless ($noimg){
      # download images to prefix (e.g. my-plugins/htdocs/), stripping mask from the file path
        my @images = $node->{$species}->{$field} =~ m/src=["']{1}[\/]?([^"^']+)["']{1}/g;
        if(@images){
          foreach my $img (@images){
            my $basename=basename($img);
            my $image_file = sprintf('%s/%s',$image_path,$basename);
            my $dirname = dirname($image_file);
            make_path($dirname) unless (-d $dirname);
            printf STDERR ("Downloading $host/$img, save to $image_file...\n") unless $quiet;
            getstore("http://$host/$img", $image_file);
            warn "$host/$img was not downloaded to $image_file!\n" unless -e $image_file or $quiet;
            # now fix the path in the file
            $image_file =~ s/^.+htdocs//;
            $node->{$species}->{$field} =~ s/src=["']{1}[^"^']*$img["']{1}/src="$image_file"/smg;
          }
        }
      }
      printf FH ("<!-- {%s} --><a name=\"%s\"></a>\n%s\n<!-- {%s} -->\n",$field, $field, $node->{$species}->{$field} || "",$field);
    }
    my $pubsurl = sprintf("http://%s/%s",$host,$node->{$species}->{'pubs'});
    my $pubsxml = get($pubsurl);
    $pubsxml =~ s/[^[:ascii:]]//g;
    my $pubs = XMLin(encode('utf-8',$pubsxml));
    my @publist;
    if(defined($pubs->{'node'})){
    if(ref($pubs->{'node'}) eq 'HASH'){ $pubs->{'node'} = [ $pubs->{'node'} ]; }
    my $refnum=1;
    foreach my $pub (@{$pubs->{'node'}}){
      my $html = '';
      my $title = $pub->{'title'};
      $title =~ s/\s*\.\s*$//;
      if ($pub->{'url'}){ $title = sprintf('<a href="%s">%s</a>',$pub->{'url'},$title); }
      elsif( $pub->{'PMID'}){ $title = sprintf('<a href="http://europepmc.org/abstract/MED/%s">%s</a>',$pub->{'PMID'},$title); }
      elsif($pub->{'DOI'}){ $title = sprintf('<a href="http://dx.doi.org/%s">%s</a>',$pub->{'DOI'},$title); }
      else{ # linkify urls in title
        my $finder = URI::Find->new(sub { my($uri,$orig_url) = @_; return qq{<a href="$url">$orig_url</a>}; });   
        $finder->find(\$title);
      }
      my $authors = $pub->{'authors'} || $pub->{'author'};
      my @authlist = split(/,/,$authors);
      if(10 < scalar @authlist){
        $authors = join(',',@authlist[0..9]); # We print the first 10 authors + et al.
        $authors .= " et al";
      }
      $html .= "$title.<br>";
      $html .= sprintf("%s. ", $authors) if($authors);  
      $html .= sprintf("%s. ", $pub->{'year'}) if($pub->{'year'});  
      $html .= sprintf("%s. ", $pub->{'journal'}) if($pub->{'journal'});  
      $html .= sprintf("%s", $pub->{'volume'}) if($pub->{'volume'});  
      if($pub->{'pages'}){ $html .= sprintf(":%s.", $pub->{'pages'}); } 
      push(@publist,sprintf('<li><a id="ref-%02d"></a>%s</li>',$refnum, $html));
      $refnum++;
      }
      if(@publist){
        printf FH ("<h3>References</h3><ol>%s</ol>",join("\n",@publist));
      }
      printf FH ("<p>%s</p>",$node->{$species}->{'image_credit'}) if($node->{$species}->{'image_credit'});
    }
    close FH;
    system(sprintf('cvs add %s', $file)) if $commit;
    my ($imgurl) = $node->{$species}->{'image'} =~ /^.*src=['"]([^'^"]+)['"]/;
    next if (!$imgurl);
    printf STDERR ("Fetching %s\n", $imgurl) unless $quiet;
    
    make_path($tmp) unless (-d $tmp);
    my $tmpimg = sprintf ('%s/%s.png',$tmp,ucfirst($species));
    getstore($imgurl,$tmpimg);
    next unless (-e $tmpimg);
    my $image = Imager->new();
    $image->read(file=>$tmpimg);
    
    my $image64 = $image->scale(xpixels=>64, ypixels=>64);
    my $image_filename = sprintf("%s/%s.png",$imgdir64,ucfirst($species));
    printf STDERR ("Writing %s\n",$image_filename) unless $quiet;
    $image64->write(file=>$image_filename);
    system(sprintf('cvs add %s', $image_filename)) if $commit;
    
    my $image48 = $image->scale(xpixels=>48, ypixels=>48);
    $image_filename = sprintf("%s/%s.png",$imgdir48,ucfirst($species));
    printf STDERR ("Writing %s\n",$image_filename) unless $quiet;
    $image48->write(file=>$image_filename);

    my $image16 = $image->scale(xpixels=>16, ypixels=>16, type => 'nonprop');
    $image_filename = sprintf("%s/%s.png",$imgdir16,ucfirst($species));
    printf STDERR ("Writing %s\n",$image_filename) unless $quiet;
    $image16->write(file=>$image_filename);
    system(sprintf('cvs add %s', $image_filename)) if $commit;

    unlink $tmpimg;
  }
  if($commit){
    printf STDERR ("Committing: %s\n", join(" ", @commits)) unless $quiet;
    $commit = sprintf(':ext:%s@cvs.sanger.ac.uk:/cvsroot/CVSmaster',$commit);
    system(sprintf(qq{cvs -d %s commit -m "%s" %s}, $commit, $message, join(" ", @commits)));
  }
  return 0;
}

1;
