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


package EG::Drupal::Export::Species;

use strict;
use warnings;

use XML::Simple qw/XMLout/;
use Data::Dumper;


use vars qw($list $output $about_dir);
use Getopt::Long;
GetOptions('i|list=s' => \$list, 'o|output=s' => \$output, 'r|about_dir=s' => \$about_dir);

open (INFILE, "<$list") or die "$list: $!\n";
my @species = <INFILE>;
close INFILE;
chomp @species ;

$about_dir ||= '.';
my @items;
foreach my $sp (@species){
  my $file = sprintf('%s/about_%s.html',$about_dir,ucfirst $sp);
  open(FH, "<$file") or die "$!:$file\n";
  my @html = <FH>;
  close FH;
  chomp @html;
  my $content = join("",@html);
  $content =~ s/\r\l/\n/g;
  my %data = ();
  map { $data{$_}=1 } $content =~ /<!--\s*\{\s*([^}^\s]+)\s*\}\s*-->/g;
  foreach my $tag (keys %data){
    $data{$tag} = [];
    @{$data{$tag}} = $content =~ /<!--\s*\{\s*$tag\s*\}\s*-->(.+)<!--\s*\{\s*$tag\s*\}\s*-->/ms;
  }
  # delete nested tags
  foreach my $tag (keys %data){
    foreach my $killtag (keys %data){
      $_ =~ s/(<!--\s*\{\s*$killtag\s*\}\s*-->)(.+)(<!--\s*\{\s*$killtag\s*\}\s*-->)//gm for @{$data{$tag}};
    }
  }
  $data{'name'} = [ $sp ];
  push(@items, \%data );
} 

open (OUTPUT, "+>:encoding(utf-8)", $output);
print OUTPUT XMLout({'item'=>\@items});
close OUTPUT;
