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

package EnsEMBL::Web::Component::Gene;

sub has_image {
    my $self = shift;
    $self->{'has_image'} = shift if @_;
    return $self->{'has_image'} || 0;
}

sub homolog_type {
  my $self = shift;
  my $hub = $self->hub;
  
  my ($match_type, %desc_mapping);

  if ($hub->action eq 'Compara_Ortholog') {
    $match_type = 'Orthologue';
    %desc_mapping = (
      ortholog_one2one          => '1 to 1 orthologue',
      apparent_ortholog_one2one => '1 to 1 orthologue (apparent)',
      ortholog_one2many         => '1 to many orthologue',
      ortholog_many2many        => 'many to many orthologue',
      possible_ortholog         => 'possible orthologue',
    );
  } 
  elsif ($hub->action eq 'Compara_Homoeolog') {
    $match_type = 'Homoeologue';
    %desc_mapping = (
      homoeolog_one2one         => '1-to-1',
      homoeolog_one2many        => '1-to-many',
      homoeolog_many2many       => 'many-to-many',
    );
  } 
  else {
    $match_type = 'Paralogue';
    %desc_mapping = (
      within_species_paralog    => 'paralogue (within species)',
      putative_gene_split       => 'putative gene split',
      contiguous_gene_split     => 'contiguous gene split',
    );
  }

  return $match_type, \%desc_mapping;
}

1;

