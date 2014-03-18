#!/usr/local/bin/perl
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


use strict;
use FindBin qw($Bin);
use Data::Dumper;
use BioMart::Initializer;
use BioMart::Query;
use BioMart::QueryRunner;
use LWP::Simple qw(getstore);
use Capture::Tiny qw(capture);

my $REGISTRY_URL  = 'http://www.ebi.ac.uk/pride/biomart/martservice?type=registry';

use lib $Bin;
use LibDirs;
use LoadPlugins;
use EnsEMBL::Web::SpeciesDefs;
my $species_defs = EnsEMBL::Web::SpeciesDefs->new;

# crude check to see which ini files in this plugin already have pride configured
(my $plugin = lc($SiteDefs::ENSEMBL_SITETYPE)) =~ s/^ensembl\s*//;
my $grep = `grep "DS_1436\\s*=" $Bin/../../eg-web-$plugin/conf/ini-files/*`;

my %site_tax  = map {$species_defs->get_config($_, 'TAXONOMY_ID') => $_} $species_defs->valid_species;

print "Fetching species from PRIDE BioMart...\n";
my @pride_tax = get_pride_taxon_ids();

print "\nIt looks like PRIDE is already configured in these ini files:\n";
print "$grep\n";

print "Species that should have PRIDE enabled:\n";
foreach (sort map {$site_tax{$_}} @pride_tax) {
  next unless $_;
  print sprintf "%-40s%s\n", $_, ($grep =~ /$_/mi ? 'ALREADY ENABLED' : "<-- NOT YET ENABLED"); 
}
print "\n";

#------------------------------------------------------------------------------

sub get_pride_taxon_ids {
  my $tmp_file = '/tmp/pride-biomart-registry.xml';
  
  getstore($REGISTRY_URL, $tmp_file);
  
  my $initializer = BioMart::Initializer->new(registryFile => $tmp_file, action => 'clean');
  my $registry = $initializer->getRegistry;
  
  my $query = BioMart::Query->new(registry => $registry, virtualSchemaName => 'default');  
  $query->setDataset('pride');
  $query->addAttribute('newt_ac'); # taxon id
  $query->formatter('TXT');
  
  my $query_runner = BioMart::QueryRunner->new;
  $query_runner->uniqueRowsOnly(1);
  $query_runner->execute($query);
  
  # capturing stdout seems daft, but I can't see an easy 
  # way to get at the raw data using the biomart api
  my $text = capture { $query_runner->printResults };
  my @rows = split /\n/, $text;
  
  return @rows;
}

