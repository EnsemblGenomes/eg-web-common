package EnsEMBL::Web::ImageConfig::gene_summary;

use strict;
sub init {
  my $self = shift;

  $self->set_parameters({
    sortable_tracks => 1, # allow the user to reorder tracks
    opt_lines       => 1, # draw registry lines
  });

  $self->create_menus(qw(
    sequence
    transcript
    prediction
    variation
    somatic
    functional
    external_data
    user_data
    other
    information
  ));

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

}


1;
