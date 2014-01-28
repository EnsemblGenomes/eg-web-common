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

# Name:        drupal_create_htdocs_import.pl --file=eg-plants-files.txt --output=import-plants-html.xml --archive=ensembl-media --prefix=static/images/ensembl-media
# Author:      Jay Humphrey jhumphre@ebi.ac.uk EnsemblGenomes Web Team
# Description: read a list of files and output RSS XML for importing them to Drupal site ensemblgenomes.org
# Parameters:
#   --input=file: text file containing a list of files to import
#   --output=file: file to write results to, e.g. eg-common-import-to-drupal.xml
#   --archive=dir: create dir.tar containing this xml and all images used in the exported HTML docs
#   --prefix=dir: The path to images on the destination site, transforms <img src="/img/species/Oryza_sativa.png"> into <img src="/dir/img/species/Oryza_sativa">

use strict;
use warnings;

use vars qw($input $output $archive $prefix $json $link_append);
use Getopt::Long;
use XML::RSS;
use HTML::Entities;
use Archive::Tar;
use File::Copy;
use File::Path qw/remove_tree make_path/;

GetOptions('input=s' => \$input, 'output=s' => \$output, 'archive=s' => \$archive, 'prefix=s' => \$prefix, 'json=s' => \$json, 'link_append=s' => \$link_append);

if(!$input or !$output){
  print ("Options --input and --output must be set. See source comments for further information.\n");
  exit 0;
}
open (INFILE, "<$input") or die "$input: $!\n";
my @files = <INFILE>;
close INFILE;
chomp @files;

my $count = 0;
my $packed = 0;
printf STDERR ("Reading %d files in %s...\n",scalar @files,$input);
my $rss = XML::RSS->new('version' => '2.0');
$rss->channel(
  title => 'Ensembl Import',
  'link' => 'http://ensemblgenomes.org',
  description => 'none',
);
my @menu; 
my @media;
foreach my $file (@files){
  open(FH, "<$file") or die "$!:$file\n";
  my @html = <FH>;
  close FH;
  chomp @html;
  my $content = join("",@html);
 #$content =~ s/[\r\l\n\t]/ /g;
 #$content =~ s/\s+/ /g;
  my ($title) = $content =~ m/<title>(.*)<\/title>/;
  ($title) = $content =~ m/<title>(.*)<\/title>/ unless $title;
  $content =~ s/<head.+\/head>|<[\/]?html>|<[\/]?body>//g;
  my $link = $file;
 #$link =~ tr/\//+/;
  $link =~ s/^.*htdocs\///;
  $link =~ s/\.html$|\.inc$//;
  $link =~ s/\/index$//;
  $link .= "/$link_append" if $link_append;
  my @images = $content =~ m/src=["']{1}[\/]?([^"^']+)["']{1}/g;
  if(@images){
   #Find these images
    foreach my $img (@images){
      my ($htdocs) = $file =~ m/^(.*htdocs)/;
      foreach my $path ( $htdocs, "eg-plugins/common/htdocs", "htdocs"){
        if( -f "$path/$img"){
          push(@media, "$path/$img");
          $content =~ s/src=["']{1}[\/]?$img["']{1}/src="\/$prefix\/$path\/$img"/;
          $packed++;
          last;
        }
      }
    }
  }
printf STDERR ("%s has no title!\n",$file) unless $title;
  $rss->add_item(
    'title' => $title || $file,
    'description' => $content,
    'link' => $link,
  );
  my $level = $link =~ tr/\///; #directory depth
  $level -= 1 if($link =~ /^\//);
  $level -= 2 if($link =~ /info\/docs/);
  my $menu_key = ('-' x $level) . $title || $file;
  push(@menu,[$menu_key,$link]);
  $count++;
}
open (OUTPUT, "+>$output");
print OUTPUT $rss->as_string;
close OUTPUT;
printf STDERR ("Wrote $count files to $output\n");
if($archive){
  if(! -d $archive) {mkdir($archive) or die "$archive: $!\n";}
  else{ die "$archive/ already exists! Cowardly refusing to proceed.\n";}
  my $tar = Archive::Tar->new();
  foreach my $img (@media){
    $img =~ s/\/\//\//g;
    my ($base,$dest,$ext) = fileparse($img);
  # $dest =~ s/^.+htdocs/$archive/;
    $dest =~ s/^/$archive\//; # prefix the full path
    next if -e "$dest/$base";
    make_path($dest);
    copy($img, $dest);
  # print STDERR ("copy $img to $dest\n");
     $tar->add_files("$dest/$base");
  }
  move($output,$archive);
  $tar->add_files("$archive/$output");
  $tar->write($archive . ".tar");
  remove_tree($archive);
  printf STDERR ("Created %s.tar. Copy this file to files/dev/7/ensemblgenomes.org/%s and untar. Use Ensembl RSS Importer to import File: $output\n",$archive, $prefix);
}
if($json){
  open(JF, "+>$json") or die "$!\n";
  foreach my $item (sort {  $a->[1] cmp $b->[1] } @menu){
    printf JF (qq[%s {"url":"%s"}\n],@$item);
  }
  close JF;
}

1;

