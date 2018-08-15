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

use strict;
use warnings;
use DateTime;
use Getopt::Long;
use Data::Dumper;
use HTML::Entities;
use FindBin qw($Bin);
use lib $Bin;
use LibDirs;
use EnsEMBL::Web::DBHub; 
use EnsEMBL::Web::DBSQL::MetaDataAdaptor;

my $dir  = '.';
my $index_list;

GetOptions(
  'dir=s'   => \$dir,
  'index=s' => \$index_list
);

my @indices      = $index_list ? map {ucfirst} split(/,/, $index_list) : qw(Genome Seqregion);
my $hub          = EnsEMBL::Web::DBHub->new;
my $species_defs = $hub->species_defs;
my @species      = $species_defs->valid_species;
(my $division    = $species_defs->ENSEMBL_SITETYPE) =~ s/ //;
my $genomic_unit = $species_defs->GENOMIC_UNIT;
my $release      = $species_defs->SITE_RELEASE_VERSION;
my %core_dbs     = map { $species_defs->get_config($_, 'databases')->{DATABASE_CORE}->{NAME} => 1 } (@species);
my $dbh          = $hub->database('core', $species[0])->dbc->db_handle;
my $file;

my $meta_data_adaptor = EnsEMBL::Web::DBSQL::MetaDataAdaptor->new($hub);
die "Could not fetch MetaDataAdaptor - check DATABASE_METADATA configuration" unless $meta_data_adaptor;

my $dispatch = {
  Genome    => \&print_genomes,
  Seqregion => \&print_seqregions,
};

foreach my $index (@indices) {
  print "\n--- $index ---\n";
  
  my $filename = "$dir/${index}_$division.xml";
  print "starting $filename\n";

  open $file, '>' , $filename or die "Cannot open index file $filename: $!"; 
  print_header();
  $dispatch->{$index}->();
  print_footer();
  close $file;

  print "wrote $filename\n";
}

exit;

#------------------------------------------------------------------------------

sub escape { return encode_entities($_[0], q{&<>"'\''}) }

sub print_header {
  print $file qq{<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE database [ <!ENTITY auml "&#228;">]>
<database>
  <name>$division</name>
  <release>$release</release>
  <entries>};
}

sub print_footer {
  print $file qq{
  </entries>
</database>
  }
}

sub print_genomes {
   
  my @meta_keys = qw(  
    assembly.accession
    assembly.default
    assembly.name
    species.common_name
    species.display_name
    species.division
    species.production_name
    species.scientific_name
    species.taxonomy_id
  );
  
  my @meta_keys_multi = qw(
    species.alias
    species.classification
  );

  my @genome_methods = qw(
    strain
    genebuild
    is_reference
    has_pan_compara
    has_peptide_compara
    has_synteny
    has_genome_alignments
    has_other_alignments
    has_variations
  );
  
  my $key_to_field_name = sub {
    my $str = shift;
    $str =~ s/^species\.//;
    $str =~ s/\./_/;
    return $str;
  };

  foreach my $db_name (sort keys %core_dbs) {
    print "$db_name\n";
    
    # prepare the data
      
    my ($collection) = $db_name =~ /^(.+)_collection/i;
      
    $dbh->do("use $db_name");
    
    my $meta = $dbh->selectall_hashref(
      'SELECT species_id, meta_key, meta_value FROM meta WHERE meta_key IN ("' . join('", "', @meta_keys) . '") 
       ORDER BY species_id, meta_key, meta_id DESC', 
      ['species_id', 'meta_key']
    );
    
    my $meta_multi = $dbh->selectall_hashref(
      'SELECT species_id, meta_key, meta_value FROM meta WHERE meta_key IN ("' . join('", "', @meta_keys_multi) . '") 
       ORDER BY species_id, meta_key, meta_id DESC', 
       ['species_id', 'meta_key', 'meta_value']
    );
      
    # add entries
    
    foreach my $species_id (keys %$meta) {
      my $production_name = $meta->{$species_id}->{'species.production_name'}->{meta_value};  
      my $display_name    = $meta->{$species_id}->{'species.display_name'}->{meta_value}; 
      my $tax_id          = delete $meta->{$species_id}->{'species.taxonomy_id'}->{meta_value};   
  
      my $fields;
      $fields .= qq{<field name="collection">$collection</field>\n} if $collection; 
      $fields .= qq{<field name="genomic_unit">$genomic_unit</field>\n};  
      
      foreach my $key (@meta_keys) {
        if (my $value = escape($meta->{$species_id}->{$key}->{meta_value})) {
          my $name = $key_to_field_name->($key);
          $fields .= qq{<field name="$name">$value</field>\n};  
        }
      }   
      
      foreach my $key (@meta_keys_multi) {
        if (my $hash = $meta_multi->{$species_id}->{$key}) {
          my $name = $key_to_field_name->($key);
          foreach my $value (map {escape($_)} keys %$hash) {
            $fields .= qq{<field name="$name">$value</field>\n};  
          }
        }
      }   
      
      my $genome = $meta_data_adaptor->genome($production_name);
      foreach my $method (@genome_methods) {
        my $value = escape($genome->$method || '');
        $fields .= qq{<field name="$method">$value</field>\n};  
      }
      my $now = DateTime->now->ymd;

      chomp $fields;

      print $file qq{
      <entry id="$production_name">
        <name>$display_name</name>
        <dates>
          <date value="$now" type="creation"/>
          <date value="$now" type="last_modification"/>
        </dates> 
        <cross_references>
          <ref dbname="ncbi_taxonomy_id" dbkey = "$tax_id" /> 
        </cross_references>
        <additional_fields>
          $fields
        </additional_fields>
      </entry>};
    }
  }
}

sub print_seqregions {
  
  my $max_len = 100000;
  
  foreach my $db_name (sort keys %core_dbs) {
    print "$db_name\n";
      
    $dbh->do("use $db_name");
    
    my %production_name = map {@$_} @{ $dbh->selectall_arrayref("SELECT species_id, meta_value FROM meta WHERE meta_key = 'species.production_name'") };
    my %display_name    = map {@$_} @{ $dbh->selectall_arrayref("SELECT species_id, meta_value FROM meta WHERE meta_key = 'species.display_name'") };
    my %tax_id          = map {@$_} @{ $dbh->selectall_arrayref("SELECT species_id, meta_value FROM meta WHERE meta_key = 'species.taxonomy_id'") };
    
    # get seq regions from top 2 levels - along with mapping to top level 
    my $seq_regions = $dbh->selectall_arrayref(
      "SELECT DISTINCT sr.name AS seq_region_name, sr.length, asm.name AS asm_seq_region_name, cmp.asm_start, cmp.asm_end, cs.name AS coord_system_name, cs.species_id
       FROM seq_region sr JOIN coord_system cs USING (coord_system_id)
       LEFT JOIN assembly cmp ON cmp.cmp_seq_region_id = sr.seq_region_id
       LEFT JOIN seq_region asm ON asm.seq_region_id = cmp.asm_seq_region_id
       LEFT JOIN seq_region_attrib sra ON sra.seq_region_id = asm.seq_region_id
       LEFT JOIN attrib_type `at` USING(attrib_type_id) 
       WHERE (at.name = 'Top Level' OR at.name IS NULL)
       AND cs.name != 'chunk' AND cs.name != 'ignored'
       AND FIND_IN_SET('default_version', cs.attrib)",
       { Slice => {} }
    ); 
    
    foreach my $sr (@$seq_regions) {
      my $id = $sr->{species_id};
      
      my $location = $sr->{asm_seq_region_name} ?
        sprintf('%s:%s-%s', $sr->{asm_seq_region_name}, $sr->{asm_start}, $sr->{asm_end} > $sr->{asm_start} + $max_len - 1 ? $sr->{asm_start} + $max_len - 1 : $sr->{asm_end}) :
        sprintf('%s:%s-%s', $sr->{seq_region_name}, '1', $sr->{length} > $max_len ? $max_len : $sr->{length});
      
      print $file qq{
      <entry id="$sr->{seq_region_name}">
        <name>$sr->{seq_region_name}</name>
        <cross_references>
          <ref dbname="ncbi_taxonomy_id" dbkey = "$tax_id{$id}" /> 
        </cross_references>
        <additional_fields>
          <field name="species">$display_name{$id}</field>
          <field name="production_name">$production_name{$id}</field>
          <field name="length">$sr->{length}</field>
          <field name="location">$location</field>
          <field name="coord_system">$sr->{coord_system_name}</field>
          <field name="genomic_unit">$genomic_unit</field>
        </additional_fields>
      </entry>};
    }
  }
}


