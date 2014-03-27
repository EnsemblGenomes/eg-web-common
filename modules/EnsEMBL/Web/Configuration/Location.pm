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

package EnsEMBL::Web::Configuration::Location;

use strict;

sub modify_tree {
  my $self  = shift;
  my $species_defs = $self->hub->species_defs;
  
  if ($species_defs->POLYPLOIDY) {
    
    $self->get_node('Multi')->after( 
      $self->create_node('MultiPolyploid', 'Polyploid view ([[counts::intraspecies_alignments]])',
        [qw(
          summary  EnsEMBL::Web::Component::Location::MultiIdeogram
          top      EnsEMBL::Web::Component::Location::MultiTop
          botnav   EnsEMBL::Web::Component::Location::MultiBottomNav
          bottom   EnsEMBL::Web::Component::Location::MultiPolyploid
        )],
        { 'availability' => 'slice database:compara has_intraspecies_alignments', 'concise' => 'Polyploid view' }
      )
    );
    
  }
}

1;
