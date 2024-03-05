=head1 LICENSE

Copyright [2009-2024] EMBL-European Bioinformatics Institute

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

use previous qw(
  modify_tree 
  add_external_browsers
);

sub modify_tree {
  my $self  = shift;
  my $species_defs = $self->hub->species_defs;

  $self->PREV::modify_tree;
  
  if ($species_defs->POLYPLOIDY) {
    
    $self->get_node('Multi')->after( 
      $self->create_node('MultiPolyploid', 'Polyploid view',
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

## EG add community annotation link
sub add_external_browsers {
  my $self         = shift;
  
  $self->PREV::add_external_browsers(@_);

  my $hub          = $self->hub;
  my $object       = $self->object;
  my $species_defs = $hub->species_defs;

  if ($object and my $annotation_url = $species_defs->ANNOTATION_URL) {
    
    my ($sr, $start, $end) = ($object->seq_region_name, $object->seq_region_start, $object->seq_region_end);
    $annotation_url =~ s/###SEQ_REGION###/$sr/;
    $annotation_url =~ s/###START###/$start/;
    $annotation_url =~ s/###END###/$end/;

    $self->get_other_browsers_menu->prepend(
      $self->create_node(
        'Community annotation', 'Community annotation', [], 
        { url => $annotation_url, raw => 1, external => 1 }
      )
    );
  }
}

1;
