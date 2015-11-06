=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Job::VEP;

use strict;
use warnings;

use previous qw(prepare_to_dispatch);

sub prepare_to_dispatch {
  my $self    = shift;
  my $sd      = $self->hub->species_defs;
  my $data    = $self->PREV::prepare_to_dispatch(@_);
  my $species = $data->{species};
  my $dataset = $self->hub->species_defs->get_config(ucfirst($species), "SPECIES_DATASET");

  if (lc($dataset) ne lc($species)) {
    $data->{config}->{is_multispecies} = 1;  
  }

  return $data;
}

1;
