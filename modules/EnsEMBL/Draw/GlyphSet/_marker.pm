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

package EnsEMBL::Draw::GlyphSet::_marker;

## This is here to fix https://www.ebi.ac.uk/panda/jira/browse/VB-2047
## I've sent a patch to Ensembl webteam - hopefully we can drop this plugin for E73

use strict;

sub features {
  my $self  = shift;
  my $slice = $self->{'container'};
  my @features;
  
  if ($self->{'text_export'}) {
    @features = @{$slice->get_all_MarkerFeatures};
  } else {
    my $priority   = $self->my_config('priority');
    my $marker_id  = $self->my_config('marker_id');
    my $map_weight = 2;
## EG  
       @features   = @{$slice->get_all_MarkerFeatures(undef, $priority, $map_weight)};
    
    # only add the highlighted marker if not already present
    push @features, @{$slice->get_MarkerFeatures_by_Name($marker_id)} if $marker_id and !grep {$_->display_id eq $marker_id} @features; ## Force drawing of specific marker regardless of weight
##
  }
  
  foreach my $f (@features) {
    my $ms  = $f->marker->display_MarkerSynonym;
    my $id  = $ms ? $ms->name : '';
      ($id) = grep $_ ne '-', map $_->name, @{$f->marker->get_all_MarkerSynonyms || []} if $id eq '-' || $id eq '';
    
    $f->{'drawing_id'} = $id;
  }
  
  return [ sort { $a->seq_region_start <=> $b->seq_region_start } @features ];
}

1;
