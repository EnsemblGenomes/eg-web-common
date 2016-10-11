=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Form::ViewConfigForm;

use strict;
use warnings;
no warnings "uninitialized";

sub add_species_fieldset {
  my $self          = shift;
  my $species_defs  = $self->view_config->species_defs;
## EG  
  my %species       = map { $species_defs->species_label($_) => $_ } $self->view_config->hub->compara_species;
##
  foreach (sort { ($a =~ /^<.*?>(.+)/ ? $1 : $a) cmp ($b =~ /^<.*?>(.+)/ ? $1 : $b) } keys %species) { 
    # complicated if statement which basically show/hide strain or main species depending on the view you are (when you are on a main species, do not show strain species and when you are on a strain species or strain view from main species, show only strain species)
    next if ((!$self->view_config->hub->param('strain') && $self->view_config->species_defs->get_config($species{$_},'IS_STRAIN_OF')) || (($self->view_config->hub->param('strain')  || $self->view_config->species_defs->IS_STRAIN_OF) && !$self->view_config->species_defs->get_config($species{$_}, 'RELATED_TAXON'))); 
    
    $self->add_form_element({
      'fieldset'  => 'Selected species',
      'type'      => 'CheckBox',
      'label'     => $_,
      'name'      => 'species_' . lc $species{$_},
      'value'     => 'yes',
    });
  }
}

1;
