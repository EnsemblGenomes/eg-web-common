=head1 LICENSE

Copyright [2009-2014] EMBL-European Bioinformatics Institute

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

# $Id: contigviewbottom.pm,v 1.7 2013-11-27 14:23:52 ek3 Exp $

package EnsEMBL::Web::ImageConfig::contigviewbottom;

use strict;
use warnings;

use previous qw(init initialize);

sub init {
  my $self = shift;
  
  $self->create_menus(qw(
    sequence
    marker
    trans_associated
    transcript
    prediction
    dna_align_cdna
    dna_align_est
    dna_align_rna
    dna_align_other
    protein_align
    protein_feature
    rnaseq
    ditag
    simple
    genome_attribs
    misc_feature
    variation
    recombination
    somatic
    functional
    multiple_align
    conservation
    pairwise_blastz
    pairwise_tblat
    pairwise_other
    dna_align_compara
    oligo
    repeat

    chromatin_binding
    pb_intron_branch_point
    polya_sites 
    replication_profiling
    regulatory_elements
    tss
    transcriptome
    nucleosome
    dna_methylation
    histone_mod 

    wheat_alignment      
    wheat_assembly       
    wheat_transcriptomics
    wheat_ests           
    rnaseq_cultivar      
    rnaseq_tissue        
    resequencing  

    external_data
    user_data
    decorations
    information
  ));

  $self->PREV::init(@_);

  $self->load_configured_bam;
  $self->load_configured_bed;
  $self->load_configured_bedgraph;
  $self->load_configured_mw;
  $self->load_configured_gff;

  my $ml = $self->get_node('fg_methylation_legend');
  $ml->remove if $ml;
}

sub initialize {
  ## @plugin
  ## Adds blast track to the config
  my $self = shift;
  $self->PREV::initialize(@_);

  ## replace "BLAST/BLAST" with "BLAST"

  if (my $node = $self->get_node('blast')) {
    $node->set('caption', 'BLAST hits');
    $node->set('name', 'BLAST hits');
    $node->set('description', 'Track displaying BLAST hits for the selected job');
  }

  if (my $node = $self->get_node('blast_legend')) {
    $node->set('caption', 'BLAST Legend');
    $node->set('name', 'BLAST Legend');
  }
}

1;
