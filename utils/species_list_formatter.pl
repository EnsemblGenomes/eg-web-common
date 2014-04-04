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

# import/update species to dev.ensemblgenomes.org
# input: /nfs/ensemblgenomes/release-X/species.txt
# output: species_import.tsv

use strict;
use warnings;
use vars qw($pan);
use Getopt::Long;

GetOptions('pan'=>\$pan);

my $file = shift;
open(FH,"<$file") or die "Cannot open $file: $!\n";
my @all_lines = <FH>;
close(FH);

my %urltemplate = (
  'Bacteria' => 'http://bacteria.ensembl.org/%s',
  'Plants' => 'http://plants.ensembl.org/%s',
  'Protists' => 'http://protists.ensembl.org/%s',
  'Metazoa' => 'http://metazoa.ensembl.org/%s',
  'Fungi' => 'http://fungi.ensembl.org/%s',
  'Ensembl' => 'http://www.ensembl.org/%s',
);

#name	species	division	taxonomy_id	assembly	assembly_accession	genebuild	variation	pan_compara	genome_alignments	peptide_alignments other_alignments  url
chomp @all_lines;
my @headers = split(/\t/,shift(@all_lines));
push(@headers,'url');
print(join("\t",@headers) . "\n") if (!$pan);
my @pan_spp;
foreach my $line (sort @all_lines){
  chomp $line;
  my @data = split(/\t/,$line);
  die ("wrong number of columns:" . scalar @data . "\n") if(scalar @data != 14);
  if($data[2] !~ /^Ensembl$/i){ $data[2] =~ s/^Ensembl//; }
  if($data[8] =~ /Y/i){
    push(@pan_spp,\@data);
  }
  s/^Y$/1/ for @data; 
  s/^N$/0/ for @data; 
  push(@data,sprintf($urltemplate{$data[2]},$data[1]));
# my @attr = ();
# push(@attr,'Variation') if($data[7]);
# push(@attr,'Pan Compara') if($data[8]);
# push(@attr,'Genome Alignments') if($data[9]);
# push(@attr,'Other Alignments') if($data[10]);
# push(@data, join(',',@attr));

  print join("\t",@data) . "\n" if (!$pan);
}
if($pan){
  printf STDERR ("%d pan species\n",scalar @pan_spp);
  printf("<ul>\n<li>%s</li>\n</ul>\n",join("</li>\n<li>",
    map  { sprintf($urltemplate{ $_->[2] }, $_->[1]) }
    sort { $a->[0] cmp $b->[1] } @pan_spp)
  );
}

# 00 names
# 01 species
# 02 division
# 03 taxonomy_id
# 04 assembly
# 05 assembly_accession
# 06 genebuild
# 07 variation
# 08 pan_compara
# 09 genome_alignments
# 10 peptide_alignments
# 11 other_alignments
# 12 core_db
# 13 species_id
# 14 url (added)
