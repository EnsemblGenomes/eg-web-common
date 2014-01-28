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

# Name:        drupal_fetch_htdocs_rss.pl --uri=http://dev.ensemblgenomes.org/rss/ensembl --path=all
# Author:      Jay Humphrey jhumphre@ebi.ac.uk EnsemblGenomes Web Team
# Description: read a list of files and output TSV for importing them to Drupal site ensemblgenomes.org
# Parameters:
#   --root: the top of the Ensembl installation, eg /nfs/public/rw/ensembl/ensembl-genome/current/plants/
#   --uri:  the URI of the RSS feed
#   --path: the Ensembl Path of the Article to fetch from ensemblgenomes.org; 'all' is a special path on the RSS channel to fetch all Articles that have a value in the Ensembl Path field.
#   --mask: image prefix to delete from the image path
#   --prefix: path to download images: e.g. my-plugins/htdocs

package EG::Drupal;
# this could be part of a new plugin, eg-plugins/drupal

use strict;
use warnings;

use Getopt::Long;
use LWP::Simple;
use URI;
use URI::Escape;
use XML::RSS;
use HTML::Entities;
use File::Basename;
use Cwd qw/cwd/;
use File::Path qw/remove_tree make_path/;
use Date::Format;
#use Data::Dumper;

exit main();

sub new {
  my ($class) = @_;
  my $self = {};
  bless($self, $class);
  return $self;
}

sub main {
  my $obj = EG::Drupal->new;
  my ($root, $uri, $path, $mask, $prefix, @plugin);
  GetOptions('root=s' => \$root, 'uri=s' => \$uri, 'path=s' => \$path, 'mask=s' => \$mask, 'prefix=s' => \$prefix, 'plugin=s' => \@plugin);
  if($root){
    chdir($root) or die "Cannot use $root: $!\n";
    printf STDERR ("In %s\n", cwd());
  }
  my $urlparse = URI->new($uri);
  my ($host,$hostpath) = ($urlparse->host,$urlparse->path);
  $hostpath =~ tr/\//./;
  $path =~ tr/\//+/;
  $path = uri_escape($path);
  my $url = join("/",$uri,$path);
  printf ("Fetching %s ...\n", $url);
  my $tmpfile = sprintf(".%s%s.%d",$host,$hostpath,time2str("%Y%m%d%H%M%S",time)); 
  printf STDERR ("save to %s\n", $tmpfile);
  getstore($url, $tmpfile) or die "Fetch $url failed: $!\n";
  my $current_items = $obj->current($tmpfile,\@plugin);
  my $previous_items = $obj->previous($tmpfile,\@plugin);
  foreach my $item(values %{$obj->current}){
  # update check
    if(my $prev = $previous_items->{ $item->{'file'}}){
      if($prev->{'date'} eq $item->{'date'}){
        printf STDERR ("\t%s is up to date, skipping.\n",$item->{'file'});
        next;
      }
    }
  # download images to prefix (e.g. my-plugins/htdocs/), stripping prefix-mask from the file path
    my @images = $item->{'content'} =~ m/src=["']{1}[\/]?([^"^']+)["']{1}/;
    if(@images){
      foreach my $img (@images){
        my $dest = $img;
        $dest =~ s/$mask// if $mask;
        $dest =~ s/$prefix//g if $prefix; # prevent redundancy
        $dest =~ s/^/$prefix/ if $prefix;
        $dest =~ s/^\///;
        my $dirname = dirname($dest);
        make_path($dirname) unless (-d $dirname);
        printf STDERR ("Downloading $host/$img, save to $dest...\n");
        getstore("http://$host/$img", $dest);
        die "$host/$img was not downloaded to $dest!\n" unless -e $dest;
        # now fix the path in the file
        $dest =~ s/^.+htdocs//;
        $item->{'content'} =~ s/src=["']{1}[\/]?$img["']{1}/src="$dest"/;
      }
    }
  # printf STDERR ("Images %s\n", Dumper(\@images)); 
    printf ("Writing: %s (%s)\tlength %d\n", $item->{'title'},$item->{'file'},length($item->{'content'}));
    my $dest = dirname($item->{'file'});
    make_path($dest) unless -d $dest;
    open (OUTFILE, "+>", $item->{'file'}) or die "$!\n";
    print OUTFILE ($item->{'content'});
    close OUTFILE;
  }
  $obj->cleanup($tmpfile);
  return 0;
}

=head2 loadRSS
  load articles from RSS into a hashref
  Arg1: RSS file to parse
  Arg2: array ref of plugins filter (files not destined for this subdirectory will be discarded)
  Return: hashref, items hashed by file path
=cut
sub loadRSS {
  my($self,$filename,$plugin) = (@_);
  my $rss = XML::RSS->new;
  $rss->parsefile($filename);
  my %items = ();
  foreach my $entry (@{$rss->{'items'}}) {
    my $date = substr($entry->{'pubDate'}, 5, 11);
    my $file = $entry->{'link'};
    $file =~ s/^.*[\/]+([^\/]+)$/$1/;
    $file =~ s/%2B/\//g;
    my $item = {
# Title - may be different from file path if shared between eg.org and Ensembl
      'title'   => $entry->{'title'},
# Content - the HTML code
      'content' => decode_entities($entry->{'description'}),
# Link - the path of the file in Ensembl
# Strip domain and replace uri-encoded "+" with literal "/"
      'file'    => $file,
      'date'    => $date,
    };
    if(!$plugin){ #publish everything
#printf STDERR ("Including %s\n",$item->{'file'});
        $items{$item->{'file'}}=$item;
    }
    elsif( map { $item->{'file'} =~ m/$_/ } @$plugin){
#printf STDERR ("Including %s\n",$item->{'file'});
        $items{$item->{'file'}}=$item;
    }
  }
  return \%items;
}

sub current {
  my ($self,$filename,$plugin) = @_;
  if($filename){
    $self->{'current'} = $self->loadRSS($filename,$plugin);
    $self->{'current_filename'} = $filename;
  }
  return $self->{'current'} || {};
}

sub previous {
  my ($self,$filename,$plugin) = @_;
  return $self->{'previous'} if exists $self->{'previous'};
  my $basename = $self->{'current_filename'};
  return {} unless $basename;
  # find files with a similar name
  $basename =~ s/\.[0-9]+$//;
  opendir(DH, cwd);
  my @files = reverse sort grep { !/$filename/ } grep(/$basename/,readdir(DH));
  closedir(DH);
# printf STDERR ("archives: %s\n",Dumper(@files));
  if(@files){
    my ($file) = @files;
    $self->{'previous'} = $self->loadRSS($file,$plugin);
  }
  return $self->{'previous'};
}

sub cleanup {
  my ($self,$filename) = @_;
  my $basename = $self->{'current_filename'};
  return {} unless $basename;
  # find files with a similar name
  $basename =~ s/\.[0-9]+$//;
  opendir(DH, cwd);
  my @files = reverse sort grep { !/$filename/ } grep(/$basename/,readdir(DH));
  closedir(DH);
  if(@files){
    printf STDERR ("Deleting %d files: %s\n",scalar @files, join("\t\n",@files));
    unlink(@files);
  }
}
1;
