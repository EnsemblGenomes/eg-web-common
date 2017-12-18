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

package EnsEMBL::Web::Component::Gene::ComparaOrthologs;

use strict;

sub is_archaea {
  my ($self,$species) = @_;
  unless(exists($self->{'_archaea'})){
    # munge archaea in pan-compara
    my $adaptor = $self->hub->database('compara_pan_ensembl');
    my $results = $adaptor->dbc->db_handle->selectall_arrayref(qq{select g.name from ncbi_taxa_node a join ncbi_taxa_name an using (taxon_id) join ncbi_taxa_node c on (c.left_index>a.left_index and c.right_index<a.right_index) join genome_db g on (g.taxon_id=c.taxon_id) where an.name='Archaea' and an.name_class='scientific name';});
    $self->{'_archaea'}->{$_->[0]} = 1 for @$results;
  }
  return exists($self->{'_archaea'}->{$species});
}

sub _species_sets {
## Group species into sets - separate method so it can be pluggable easily
  my ($self, $orthologue_list, $skipped, $orthologue_map, $cdb) = @_;
  
  my $hub          = $self->hub;
  my $species_defs  = $self->hub->species_defs;
  my %all_analysed_species = $self->_get_all_analysed_species($cdb);
  my $set_order = [];
  my $is_pan = $self->hub->function eq 'pan_compara';
  if($is_pan){
    $set_order = [qw(all ensembl metazoa plants fungi protists bacteria archaea)];
  }
  
  my $species_sets = {
    'ensembl'     => {'title' => 'Vertebrates', 'desc' => '', 'species' => [], 'all' => 0},
    'metazoa'     => {'title' => 'Metazoa',     'desc' => '', 'species' => [], 'all' => 0},
    'plants'      => {'title' => 'Plants',      'desc' => '', 'species' => [], 'all' => 0},
    'fungi'       => {'title' => 'Fungi',       'desc' => '', 'species' => [], 'all' => 0},
    'protists'    => {'title' => 'Protists',    'desc' => '', 'species' => [], 'all' => 0},
    'bacteria'    => {'title' => 'Bacteria',    'desc' => '', 'species' => [], 'all' => 0},
    'archaea'     => {'title' => 'Archaea',     'desc' => '', 'species' => [], 'all' => 0},
    'all'         => {'title' => 'All',         'desc' => '', 'species' => [], 'all' => 0},
  };
  
  my $sets_by_species = {};
  my $spsites         = $species_defs->ENSEMBL_SPECIES_SITE();
  my ($ortho_type);
  
  foreach my $species (keys %all_analysed_species) {
    $species = ucfirst($species); # yuk!
    next if $skipped->{$species};

    my $group = $spsites->{lc($species)};
    my $sets = [];
    my $orthologues = $orthologue_list->{$species} || {};
    my $no_ortho = 0;

    if($group eq 'bacteria'){
      $group = 'archaea' if $self->is_archaea(lc $species);
    } elsif (!$is_pan){ 
      # not the pan compara page - generate groups
      $group = $species_defs->get_config($species, 'SPECIES_GROUP') || $spsites->{lc($species)} || 'Undefined';
      
      if(!exists $species_sets->{$group}){
        $species_sets->{$group} = {'title' => ucfirst $group, 'species' => [], 'all' => 0};
        push @$set_order, $group;
      }
    }

    if (!$orthologue_list->{$species} && $species ne $self->hub->species) {
      $no_ortho = 1;
    }

    foreach my $stable_id (keys %$orthologues) {
      my $orth_info = $orthologue_list->{$species}->{$stable_id};
      my $orth_desc = ucfirst($orth_info->{'homology_desc'});
      $ortho_type->{$species}{$orth_desc} = 1;
    }
    
    if ($species ne $self->hub->species && !$ortho_type->{$species}{'1-to-1'} && !$ortho_type->{$species}{'1-to-many'}
          && !$ortho_type->{$species}{'Many-to-many'}) {
      $no_ortho = 1;
    }
    
    
    foreach my $ss_name ('all', $group) {
      push @{$species_sets->{$ss_name}{'species'}}, $species;
      push (@$sets, $ss_name) if exists $species_sets->{$ss_name};
      while (my ($k, $v) = each (%{$ortho_type->{$species}})) {
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

sub in_archaea {
  my ($self, $species)=@_;
  
}

1;
