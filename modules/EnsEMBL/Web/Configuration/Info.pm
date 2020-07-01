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

package EnsEMBL::Web::Configuration::Info;

sub caption {
    my $self = shift;
    my $species_defs = $self->hub->species_defs;
    return sprintf 'Search <i>%s</i>', $species_defs->SPECIES_DISPLAY_NAME;
}

sub global_context {
  my $self         = shift;
  my $hub          = $self->model->hub;
  my $species_defs = $hub->species_defs;
  my $species      = $species_defs->get_config($hub->species, 'SPECIES_DISPLAY_NAME');
  
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
  
  $self->get_node('Annotation')->data->{'title'} = 'Details';
}

1;
