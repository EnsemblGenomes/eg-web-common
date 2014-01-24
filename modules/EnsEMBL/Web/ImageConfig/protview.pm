package EnsEMBL::Web::ImageConfig::protview;

use strict;


sub init {
  my ($self) = @_;

  $self->set_parameters({ sortable_tracks => 'drag' });

## EG @ switched 'feature' to 'protein_feature' to be consistent with contigviewbottom
  $self->create_menus(qw(
    domain
    feature
    protein_feature
    variation
    external_data
    user_data
    other
    information
  ));
## EG
  
  $self->load_tracks;
  $self->load_configured_das;
  
  $self->modify_configs(
    [ 'variation', 'somatic' ],
    { menu => 'no' }
  );
  
  $self->modify_configs(
    [ 'variation_feature_variation', 'somatic_mutation_COSMIC' ],
    { menu => 'yes', glyphset => 'P_variation', display => 'normal', strand => 'r', colourset => 'protein_feature', depth => 1e5 }
  );
  
  $self->modify_configs(
    [ 'variation_legend' ],
    { glyphset => 'P_variation_legend' }
  );
  
  my $translation = $self->hub->core_objects->{'transcript'} ? $self->hub->core_objects->{'transcript'}->Obj->translation : undef;
  my $id = $translation ? $translation->stable_id : $self->hub->species_defs->ENSEMBL_SITETYPE.' Protein'; 
  $self->add_tracks('other',
    [ 'scalebar',       'Scale bar', 'P_scalebar', { display => 'normal', strand => 'r' }],
    [ 'exon_structure', $id, 'P_protein',  { display => 'normal', strand => 'f', colourset => 'protein_feature', menu => 'no' }],
  );
}

1;
