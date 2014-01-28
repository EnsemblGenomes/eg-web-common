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

package EnsEMBL::Web::Component::Gene::PanCompara_Portal;

use base qw(EnsEMBL::Web::Component::Portal);
use strict;

sub content {
  my $self         = shift;
  my $hub          = $self->hub;
  my $availability = $self->object->availability;
  my $location     = $hub->url({ type => 'Location',  action => 'Compara' });

  $self->{'buttons'} = [
    { title => 'Gene tree',          img => 'compara_tree',  url => $availability->{'has_gene_tree_pan'}  ? $hub->url({ action => 'Compara_Tree/pan_compara'       }) : '' },
    { title => 'Orthologues',        img => 'pan_compara_ortho', url => $availability->{'has_orthologs_pan'}  ? $hub->url({ action => 'Compara_Ortholog/pan_compara'   }) : '' },
  ];

  my $html  = $self->SUPER::content;

  $html .= qq{<p><a target="_blank" href="http://ensemblgenomes.org/info/species?pan_compara=1">Species list</a> (will open in a new window)</p>};
  $html .= qq{<p>More views of comparative genomics data, such as multiple alignments and synteny, are available on the <a href="$location">Location</a> page for this gene.</p>};

  return $html;
}

1;
