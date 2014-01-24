package EnsEMBL::Web::Configuration::Info;

sub caption {
    my $self = shift;
    my $species_defs = $self->hub->species_defs;
    return sprintf 'Search <i>%s</i>', $species_defs->SPECIES_COMMON_NAME;
}

sub global_context {
  my $self         = shift;
  my $hub          = $self->model->hub;
  my $species_defs = $hub->species_defs;
  my $species      = $species_defs->get_config($hub->species, 'SPECIES_COMMON_NAME');
  
  if ($species and $species ne 'common') {
    $self->page->global_context->add_entry(
      type    => 'species',
      caption => sprintf('%s (%s)', $species, $species_defs->ASSEMBLY_NAME),
      url     => $hub->url({ type => 'Info', action => 'Index', __clear => 1 }),
      class   => 'active'
    );
  }
}

sub modify_tree {
  my $self  = shift;

  $self->delete_node('WhatsNew');


  $self->create_node('PanComparaSpecies', 'Pan Compara Species',
    [qw(pan_species EnsEMBL::Web::Component::Info::PanComparaSpecies)],
    { availability => 1, title => 'Pan Compara Species' }
  );
  $self->get_node('Annotation')->data->{'title'} = 'Details';
}

1;
