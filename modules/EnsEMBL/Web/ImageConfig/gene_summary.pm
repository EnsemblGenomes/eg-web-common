=head1 LICENSE

Copyright [2009-2022] EMBL-European Bioinformatics Institute

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
use warnings;
sub init_cacheable {
  ## @override
  my $self  = shift;
  my $sd    = $self->hub->species_defs;

  $self->SUPER::init_cacheable(@_);

  $self->set_parameters({
    'image_resizeable'  => 1,
    'sortable_tracks'   => 'drag', # allow the user to reorder tracks
    'opt_lines'         => 1, # draw registry lines
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
    dna_align_cdna

    external_data
    user_data
    other
    information
  ));
##

  if (my $gencode_version = $sd->GENCODE_VERSION || "") {
    $self->add_track('transcript', 'gencode', "Basic Gene Annotations from $gencode_version", '_gencode', {
      labelcaption  => "Genes (Basic set from $gencode_version)",
      display       => 'off',
      description   => 'The GENCODE set is the gene set for human and mouse. GENCODE Basic is a subset of representative transcripts (splice variants).',
      sortable      => 1,
      colours       => $self->species_defs->colour('gene'),
      label_key     => '[biotype]',
      logic_names   => ['proj_ensembl',  'proj_ncrna', 'proj_havana_ig_gene', 'havana_ig_gene', 'ensembl_havana_ig_gene', 'proj_ensembl_havana_lincrna', 'proj_havana', 'ensembl', 'mt_genbank_import', 'ensembl_havana_lincrna', 'proj_ensembl_havana_ig_gene', 'ncrna', 'assembly_patch_ensembl', 'ensembl_havana_gene', 'ensembl_lincrna', 'proj_ensembl_havana_gene', 'havana'],
      renderers     =>  [
        'off',                     'Off',
        'gene_nolabel',            'No exon structure without labels',
        'gene_label',              'No exon structure with labels',
        'transcript_nolabel',      'Expanded without labels',
        'transcript_label',        'Expanded with labels',
        'collapsed_nolabel',       'Collapsed without labels',
        'collapsed_label',         'Collapsed with labels',
        'transcript_label_coding', 'Coding transcripts only (in coding genes)',
      ],
    });
  }

  $self->add_tracks('other',
    [ 'scalebar',  '', 'scalebar',  { display => 'normal', strand => 'b', name => 'Scale bar', description => 'Shows the scalebar' }],
    [ 'ruler',     '', 'ruler',     { display => 'normal', strand => 'b', name => 'Ruler',     description => 'Shows the length of the region being displayed' }],
    [ 'draggable', '', 'draggable', { display => 'normal', strand => 'b', menu => 'no' }],
  );

  $self->add_tracks('information',
    [ 'missing', '', 'text', { display => 'normal', strand => 'r', name => 'Disabled track summary', description => 'Show counts of number of tracks turned off by the user' }],
    [ 'info',    '', 'text', { display => 'normal', strand => 'r', name => 'Information',            description => 'Details of the region shown in the image' }]
  );

  $self->add_tracks('sequence',
    [ 'contig', 'Contigs',  'contig', { display => 'normal', strand => 'r' }]
  );

  $self->load_tracks;
## EG
  $self->load_configured_bed;
  $self->load_configured_bigwig;
##

  $self->modify_configs(
    [ 'fg_regulatory_features_funcgen', 'transcript', 'prediction', 'variation' ],
    { display => 'off' }
  );
  

## EG
  $self->modify_configs(	 
    [qw(transcript_core_ensembl transcript_core_sg transcript_core_ncRNA transcript_core_trna transcript_core_ensembl_bacteria_alignment transcript_core_ena transcript_core_ena_genes transcript_core_ncrna)],
    { display => 'transcript_label' }
  );
## EG

## EG
  my $ml = $self->get_node('fg_methylation_legend');
  $ml->remove if $ml;
##
}

1;
