=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::Hub;

use strict;
use warnings;
use List::Util qw(min max);

use previous qw(new);

## EG - set correct factory type for polyploid view
sub new {
  my $self = shift->PREV::new(@_);
  $self->{'factorytype'} = 'MultipleLocation' if $self->{'type'} eq 'Location' && $self->{'action'} eq 'MultiPolyploid';
  return $self;
}

## EG
# intra_species_alignments() is a replacement for the lookup stored in MULTI.packed
# E.g. $species_defs->multi_hash->{'DATABASE_COMPARA'}->{'INTRA_SPECIES_ALIGNMENTS'}\
#                   ->{'REGION_SUMMARY'}->{$species}->{$seq_region}
#
# We do this on the fly because we have too many alignments to put into the packed configs
##

sub intra_species_alignments {
  my ($self, $cdb, $species, $slice_or_seq_region) = @_;

  return [] unless $self->species_defs->HAS_INTRASPECIES_ALIGNMENTS;

  my $slice;
  my $seq_region;

  if (ref($slice_or_seq_region) =~ /slice/i) {
    $slice      = $slice_or_seq_region;
    $seq_region = $slice->seq_region_name;
  } else {
    $slice      = undef;
    $seq_region = $slice_or_seq_region;
  }

  return [] if $cdb ne 'DATABASE_COMPARA'; ## only implemented for compara
  
  my $cache_key = "$cdb--$species--$seq_region";
  
  if (!$self->{_intra_species_alignments}->{$cache_key}) {
  
    my $compara_db = $self->database('compara');  
    return [] if !$compara_db;

    my $genomedb_adaptor            = $compara_db->get_adaptor('GenomeDB');
    my $genomic_align_block_adaptor = $compara_db->get_adaptor('GenomicAlignBlock');
    my $genomic_align_adaptor       = $compara_db->get_adaptor('GenomicAlign');
    my $mlss_adaptor                = $compara_db->get_adaptor('MethodLinkSpeciesSet');
    my $dnafrag_adaptor             = $compara_db->get_adaptor('DnaFrag');
       
    my ($genomedb, $source_dnafrag);
    eval {  
      $genomedb = $genomedb_adaptor->fetch_by_registry_name($species);
      $source_dnafrag = $dnafrag_adaptor->fetch_by_GenomeDB_and_name($genomedb, $seq_region);
    };
    return [] unless $source_dnafrag;
 
    my @comparisons;
    

    my @methods = qw(LASTZ_NET TRANSLATED_BLAT_NET TRANSLATED_BLAT BLASTZ_NET);
    push @methods, 'ATAC' if $SiteDefs::ENSEMBL_SITETYPE =~ /plants/i;

    foreach my $method (@methods) { 
      my $mlss = $mlss_adaptor->fetch_by_method_link_type_GenomeDBs($method, [$genomedb], 1);
      next unless $mlss;
      
      my $genomic_align_blocks;
      
      if ($slice) {
        $genomic_align_blocks = $genomic_align_block_adaptor->fetch_all_by_MethodLinkSpeciesSet_Slice($mlss, $slice);      
      } else {
        $genomic_align_blocks = $genomic_align_block_adaptor->fetch_all_by_MethodLinkSpeciesSet_DnaFrag($mlss, $source_dnafrag);
      }

      my %dnafrag_groups_href;
      my %group_info;
    
      foreach my $genomic_align_block (@$genomic_align_blocks) {
        my $group_id = $genomic_align_block->group_id;
        my $aligns   = $genomic_align_adaptor->fetch_all_by_GenomicAlignBlock($genomic_align_block);
        
        foreach my $align (@$aligns) {
          if ($align->dnafrag->name ne $source_dnafrag->name) {
            if (!defined $dnafrag_groups_href{$align->dnafrag->name()}) {
              # Create a new unique list of group_ids for this target dnafrag
              my $group_ids_href = {$group_id => 1};
              $dnafrag_groups_href{$align->dnafrag->name()} = $group_ids_href;
            }
            else {
              # If group_id not there yet, add it to the list of group_ids for this target dnafrag
              if (! defined $dnafrag_groups_href{$align->dnafrag->name()}->{$group_id}) {
                $dnafrag_groups_href{$align->dnafrag->name()}->{$group_id} = 1;
              }
            }
          }
          else {
            # get the coordinates for the group
            if (defined $group_info{$group_id}) {
              $group_info{$group_id} = {
                start => min( $group_info{$group_id}->{start}, $align->dnafrag_start ),
                end   => max( $group_info{$group_id}->{end},   $align->dnafrag_end ),
              }
            }
            else {
              $group_info{$group_id} = {
                start => $align->dnafrag_start,
                end   => $align->dnafrag_end,
              }
            }
          }
        }
      }

      # EG-2183 - get sub-genome components for polyploidy genomes
      my %target_sub_genomes;
      if ($self->species_defs->POLYPLOIDY) {
        my $dbh         = $self->database('core')->dbc->db_handle;
        my $sub_genomes = $dbh->selectall_arrayref(
          "SELECT sr.name, sra.value FROM seq_region sr
           JOIN seq_region_attrib sra USING (seq_region_id)
           JOIN attrib_type at USING (attrib_type_id)
           WHERE sr.name IN ('" . join("', '", keys %dnafrag_groups_href)  . "')
           AND at.code = 'genome_component'"
        );        
        %target_sub_genomes = map {$_->[0] => $_->[1]} @{$sub_genomes};     
      }
      
      # Built a list of a comparison objects, one comparison object per group_id and per pair of source/target dnafrags

      foreach my $target_name (keys %dnafrag_groups_href) {
        my $group_ids_href = $dnafrag_groups_href{$target_name};

        foreach my $group_id (keys (%$group_ids_href)) {
          my $target_info = $group_info{$group_id};
            
          push @comparisons, {
            'species'     => {
                "$species--$target_name" => 1,
                "$species--$seq_region"  => 1,
            },
            'target_name' => $target_name,
            'start'       => $target_info->{start},
            'end'         => $target_info->{end},
            'id'          => $mlss->dbID,
            'name'        => $mlss->name,
            'type'        => $mlss->method->type,
            'class'       => $mlss->method->class,
            'homologue'   => undef, ## Not implemented for EG
            'target_sub_genome' => $target_sub_genomes{$target_name},
          };
        }
      }
    } 
    
    $self->{_intra_species_alignments}->{$cache_key} = \@comparisons;
  }
  
  return $self->{_intra_species_alignments}->{$cache_key};
}

## EG - get species list from compara db (ENSEMBL-4604, ENSEMBL-4584)
sub compara_species {
  my $self       = shift;
  my $function   = $self->function;
  
  if ($self->action eq 'ComparaOrthologs') {
    # running in modal context, need to get function from referer
    $function = $self->referer->{ENSEMBL_FUNCTION};
  }

  my $compara_db = $function eq 'pan_compara' ? 'compara_pan_ensembl' : 'compara';
  my $genome_dbs = $self->database($compara_db)->get_GenomeDBAdaptor->fetch_all;
  
  return map {$_->name} @$genome_dbs;
}
##

1;
