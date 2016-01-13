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
  
}

1;
