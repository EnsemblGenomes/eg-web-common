=head1 LICENSE

Copyright [2009-2022] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Gene::ComparaOrthologs;

use strict;

sub species_set_config {
  my ($self, $cdb) = @_;
  my $set_order       = [];
  my $species_sets    = {};
  my $is_pan          = $cdb =~/compara_pan_ensembl/;

  if ($is_pan) {
    $set_order    = [qw(all vertebrates metazoa plants fungi protists bacteria archaea)];
    $species_sets = {
      'vertebrates' => {'title' => 'Vertebrates', 'desc' => '', 'species' => [], 'all' => 0},
      'metazoa'     => {'title' => 'Metazoa',     'desc' => '', 'species' => [], 'all' => 0},
      'plants'      => {'title' => 'Plants',      'desc' => '', 'species' => [], 'all' => 0},
      'fungi'       => {'title' => 'Fungi',       'desc' => '', 'species' => [], 'all' => 0},
      'protists'    => {'title' => 'Protists',    'desc' => '', 'species' => [], 'all' => 0},
      'bacteria'    => {'title' => 'Bacteria',    'desc' => '', 'species' => [], 'all' => 0},
      'archaea'     => {'title' => 'Archaea',     'desc' => '', 'species' => [], 'all' => 0},
      'all'         => {'title' => 'All',         'desc' => '', 'species' => [], 'all' => 0},
    };
  }
  return ($set_order, $species_sets);
}

  
1;
