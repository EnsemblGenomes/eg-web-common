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
  my $species_defs = $self->hub->species_defs;

  my @unsorted        = ();
  my $set_order       = [];
  my $species_sets    = {};
  my $is_pan          = $cdb =~/compara_pan_ensembl/;

  if ($is_pan) {
    $set_order    = [qw(all vertebrates metazoa plants fungi protists bacteria archaea)];
    $species_sets = {
      'vertebrates' => {'title' => 'Vertebrates'},
      'metazoa'     => {'title' => 'Metazoa'},
      'plants'      => {'title' => 'Plants'},
      'fungi'       => {'title' => 'Fungi'},
      'protists'    => {'title' => 'Protists'},
      'bacteria'    => {'title' => 'Bacteria'},
      'archaea'     => {'title' => 'Archaea'},
      'all'         => {'title' => 'All'},
    };
  }
  else {
    $species_sets = {
      'all'         => {'title' => 'All'},
    };

    ## Work out the species sets from taxonomic groups

    my $compara_spp = $species_defs->multi_hash->{'DATABASE_COMPARA'}{'COMPARA_SPECIES'};
    my $lookup      = $species_defs->prodnames_to_urls_lookup;

    foreach my $prod_name (keys %$compara_spp) {

      next if $prod_name eq 'ancestral_sequences';
      my $species = $lookup->{$prod_name};
      next unless $species;
      my $group   = $species_defs->get_config($species, 'SPECIES_GROUP') || 'Undefined';

      if (!exists $species_sets->{$group}){
        $species_sets->{$group} = {'title' => ucfirst $group};
        push @unsorted, $group;
      }
    }

    @$set_order = sort (@unsorted);
    unshift(@$set_order, 'all');
  }
  return ($set_order, $species_sets);
}

  
1;
