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

package EnsEMBL::Web::ImageConfig::gene_summary;

use strict;
sub init {
  my $self = shift;

  $self->set_parameters({
    sortable_tracks => 1, # allow the user to reorder tracks
    opt_lines       => 1, # draw registry lines
  });

## EG
  $self->create_menus(qw(
    sequence
    transcript
    rnaseq
    prediction
    variation
    somatic
    functional

    chromatin_binding
    pb_intron_branch_point
    polya_sites 
    replication_profiling
    regulatory_elements
    transcriptome
    nucleosome
    dna_methylation
    histone_mod 

    external_data
    user_data
    other
    information
  ));
##

  $self->add_tracks('other',    
    [ 'scalebar',  '', 'scalebar',  { display => 'normal', strand => 'b', name => 'Scale bar', description => 'Shows the scalebar' }],
    [ 'ruler',     '', 'ruler',     { display => 'normal', strand => 'b', name => 'Ruler',     description => 'Shows the length of the region being displayed' }],
    [ 'draggable', '', 'draggable', { display => 'normal', strand => 'b', menu => 'no' }],
  );
  
  $self->add_tracks('information',
    [ 'info',    '', 'text', { display => 'normal', strand => 'r', name => 'Information',            description => 'Details of the region shown in the image' }]
  );
  
  $self->add_tracks('sequence',
    [ 'contig', 'Contigs',  'contig', { display => 'normal', strand => 'r' }]
  );

  $self->load_tracks;
  $self->load_configured_das;
  $self->load_configured_bed;

  $self->modify_configs(
    [ 'fg_regulatory_features_funcgen', 'transcript', 'prediction', 'variation' ],
    { display => 'off' }
  );
  

## EG
  $self->modify_configs(	 
    [qw(transcript_core_ensembl transcript_core_sg transcript_core_ncRNA transcript_core_trna transcript_core_ensembl_bacteria_alignment transcript_core_ena transcript_core_ena_genes transcript_core_ncrna)],
    {qw(display transcript_label)}
  );
## EG

## EG
  my $ml = $self->get_node('fg_methylation_legend');
  $ml->remove if $ml;
##

}

1;
