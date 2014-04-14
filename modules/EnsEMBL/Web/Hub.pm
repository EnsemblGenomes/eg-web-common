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

## EG
# intra_species_alignments() is a replacement for the lookup stored in MULTI.packed
# E.g. $species_defs->multi_hash->{'DATABASE_COMPARA'}->{'INTRA_SPECIES_ALIGNMENTS'}\
#                   ->{'REGION_SUMMARY'}->{$species}->{$seq_region}
#
# We do this on the fly because we have too many alignments to put into the packed configs
##

sub intra_species_alignments {
  my ($self, $cdb, $species, $seq_region) = @_;
  
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
       
    my $genomedb       = $genomedb_adaptor->fetch_by_registry_name($species);
    my $source_dnafrag = $dnafrag_adaptor->fetch_by_GenomeDB_and_name($genomedb, $seq_region);
    return [] unless $source_dnafrag;
 
    my @comparisons;
    
    foreach my $method (qw(LASTZ_NET TRANSLATED_BLAT_NET TRANSLATED_BLAT BLASTZ_NET)) { 
      my $mlss = $mlss_adaptor->fetch_by_method_link_type_GenomeDBs($method, [$genomedb]);
      next unless $mlss;
      
      my $genomic_align_blocks = $genomic_align_block_adaptor->fetch_all_by_MethodLinkSpeciesSet_DnaFrag($mlss, $source_dnafrag);
    
      my %dnafrag_group;
      my %group_info;
    
      foreach my $genomic_align_block (@$genomic_align_blocks) {
        my $group_id = $genomic_align_block->group_id;
        my $aligns   = $genomic_align_adaptor->fetch_all_by_GenomicAlignBlock($genomic_align_block);
        
        foreach my $align (@$aligns) {
    
          if ($align->dnafrag->name ne $source_dnafrag->name) {
            $dnafrag_group{$align->dnafrag->name} = $group_id;
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
      
      foreach my $target_name (keys %dnafrag_group) {
        my $group_id    = $dnafrag_group{$target_name};
        my $target_info = $group_info{$group_id};        
        
        push @comparisons, {
          'species'     => {
            "$species--$target_name" => 1,
            "$species--$seq_region" => 1,
          },
          'target_name' => $target_name,
          'start'       => $target_info->{start},
          'end'         => $target_info->{end},
          'id'          => $mlss->dbID,
          'name'        => $mlss->name,
          'type'        => $mlss->method->type,
          'class'       => $mlss->method->class,
          'homologue'   => undef, ## Not implemented for EG
        };
      }
    } 
    
    $self->{_intra_species_alignments}->{$cache_key} = \@comparisons;
  }
  
  return $self->{_intra_species_alignments}->{$cache_key};
}

1;
