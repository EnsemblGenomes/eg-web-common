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

sub _species_sets {
## Group species into sets - separate method so it can be pluggable easily
  my ($self, $orthologue_list, $orthologue_map, $cdb) = @_;
  
  my $hub             = $self->hub;
  my $species_defs    = $self->hub->species_defs;
  my $lookup          = {}; 
  my $compara_spp     = {};
  my $sets_by_species = {};
  my $set_order       = [];
  my $is_pan          = $cdb =~/compara_pan_ensembl/;
  my $pan_info        = $is_pan ? $species_defs->multi_val('PAN_COMPARA_LOOKUP') : {};

  if ($is_pan) {
    $set_order    = [qw(all vertebrates metazoa plants fungi protists bacteria archaea)];
    foreach (keys %$pan_info) {
      $compara_spp->{$_}  = 1;
      $lookup->{$_}       = $pan_info->{$_}{'species_url'};
    }
  }
  else {
    $compara_spp  = $species_defs->multi_hash->{'DATABASE_COMPARA'}{'COMPARA_SPECIES'};
    $lookup       = $hub->species_defs->prodnames_to_urls_lookup;
  }
  
  my $species_sets = $is_pan ? {
    'vertebrates' => {'title' => 'Vertebrates', 'desc' => '', 'species' => [], 'all' => 0},
    'metazoa'     => {'title' => 'Metazoa',     'desc' => '', 'species' => [], 'all' => 0},
    'plants'      => {'title' => 'Plants',      'desc' => '', 'species' => [], 'all' => 0},
    'fungi'       => {'title' => 'Fungi',       'desc' => '', 'species' => [], 'all' => 0},
    'protists'    => {'title' => 'Protists',    'desc' => '', 'species' => [], 'all' => 0},
    'bacteria'    => {'title' => 'Bacteria',    'desc' => '', 'species' => [], 'all' => 0},
    'archaea'     => {'title' => 'Archaea',     'desc' => '', 'species' => [], 'all' => 0},
    'all'         => {'title' => 'All',         'desc' => '', 'species' => [], 'all' => 0},
  } : {
    'all'         => {'title' => 'All',         'desc' => '', 'species' => [], 'all' => 0},
  };
  
  foreach my $prod_name (keys %$compara_spp) {

    my $species = $lookup->{$prod_name};
    my $orthologues = $orthologue_list->{$species};
    my $no_ortho = 0;
    my ($orth_type, $group);
    my $sets = [];

    if (!$orthologue_list->{$species} && $species ne $self->hub->species) {
      $no_ortho = 1;
    }

    foreach my $stable_id (keys %$orthologues) {
      my $orth_info = $orthologue_list->{$species}->{$stable_id};
      my $orth_desc = ucfirst($orth_info->{'homology_desc'});
      $orth_type->{$species}{$orth_desc} = 1;
    }

    if ($species ne $self->hub->species && !$orth_type->{$species}{'1-to-1'} && !$orth_type->{$species}{'1-to-many'}
          && !$orth_type->{$species}{'Many-to-many'}) {
      $no_ortho = 1;
    }

    ## Sort into groups
    if ($is_pan) {
      $group = $pan_info->{$prod_name}{'subdivision'} ? $pan_info->{$prod_name}{'subdivision'} : $pan_info->{$prod_name}{'division'};
    }
    else {
      # not the pan compara page - generate groups
      $group = $species_defs->get_config($species, 'SPECIES_GROUP') || 'Undefined';

      if(!exists $species_sets->{$group}){
        $species_sets->{$group} = {'title' => ucfirst $group, 'species' => [], 'all' => 0};
        push @$set_order, $group;
      }
    }    

    foreach my $ss_name ('all', $group) {
      push @{$species_sets->{$ss_name}{'species'}}, $species;
      push (@$sets, $ss_name) if exists $species_sets->{$ss_name};

      while (my ($k, $v) = each (%{$orth_type->{$species}})) {
        $species_sets->{$ss_name}{$k} += $v;
      }

      $species_sets->{$ss_name}{'none'}++ if $no_ortho;
      $species_sets->{$ss_name}{'all'}++ if $species ne $self->hub->species;
    }
    
    $sets_by_species->{$species} = $sets;
  }

  if(!$is_pan) {
    my @unorder = @$set_order;
    @$set_order = sort(@unorder);
    unshift(@$set_order, 'all');
  }

  return ($species_sets, $sets_by_species, $set_order);
}

1;
