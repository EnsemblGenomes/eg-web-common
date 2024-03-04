=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::ImageConfig::MultiBottom;

use strict;

use parent qw(EnsEMBL::Web::ImageConfig::MultiSpecies);

sub init_cacheable {
  ## @override
  my $self = shift;

  $self->SUPER::init_cacheable(@_);

  $self->set_parameters({
    image_resizeable  => 1,
    sortable_tracks   => 1,  # allow the user to reorder tracks
    opt_lines         => 1,  # register lines
    spritelib         => { default => $self->species_defs->ENSEMBL_WEBROOT . '/htdocs/img/sprites' },
  });

  my $sp_img = $self->species_defs->SPECIES_IMAGE_DIR;
  if(-e $sp_img) {
    $self->set_parameters({ spritelib => {
      %{$self->get_parameter('spritelib')||{}},
      species => $sp_img,
    }});
  }

  # Add menus in the order you want them for this display
  $self->create_menus(qw(
    sequence
    marker
    transcript
    prediction
    dna_align_cdna
    dna_align_est
    dna_align_rna
    dna_align_other
    protein_align
    rnaseq
    simple
    misc_feature
    variation
    somatic
    functional
    oligo
    repeat
    user_data
    decorations
    information
  ));

  # Add in additional tracks
  $self->load_tracks;

  $self->add_tracks('sequence',
    [ 'contig', 'Contigs',  'contig',   { display => 'normal', strand => 'r', description => 'Track showing underlying assembly contigs' }],
    [ 'seq',    'Sequence', 'sequence', { display => 'normal', strand => 'b', description => 'Track showing sequence in both directions. Only displayed at 1Kb and below.', colourset => 'seq', threshold => 1, depth => 1 }],
  );

  $self->add_tracks('decorations',
    [ 'scalebar',  '', 'scalebar',      { display => 'normal', strand => 'b', name => 'Scale bar', description => 'Shows the scalebar' }],
    [ 'ruler',     '', 'ruler',         { display => 'normal', strand => 'b', name => 'Ruler',     description => 'Shows the length of the region being displayed' }],
    [ 'draggable', '', 'draggable',     { display => 'normal', strand => 'b', menu => 'no' }],
    [ 'nav',       '', 'navigation',    { display => 'normal', strand => 'b', menu => 'no' }],
## EG ENSEMBL-2967 - add species label     
    [ 'title',     '', 'species_title', { display => 'normal', strand => 'b', menu => 'no' }],
##    
  );
  
  $_->set_data('display', 'off') for grep $_->id =~ /^chr_band_/, $self->get_node('decorations')->nodes; # Turn off chromosome bands by default
}

1;
