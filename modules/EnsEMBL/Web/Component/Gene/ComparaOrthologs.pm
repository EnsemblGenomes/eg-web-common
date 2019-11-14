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
  my $is_pan = $cdb =~/compara_pan_ensembl/;
  if($is_pan){
    $set_order = [qw(all vertebrates metazoa plants fungi protists bacteria archaea)];
  }
  
  my $species_sets = {
    'vertebrates' => {'title' => 'Vertebrates', 'desc' => '', 'species' => [], 'all' => 0},
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

  foreach my $species (keys %all_analysed_species) {
    next if $skipped->{$species};

    my ($orth_type);
    my $group = $spsites->{lc($species)};

    my $sets = [];
    my $orthologues = $orthologue_list->{$species};
    my $no_ortho = 0;
    my $species_name = $species;

    # Check if orthologues doesn't exist.
    # If so, then try to convert the species name to species url by capitalizing the first letter.
    # Do the same for species name which will be used within the loop.
    if (!$orthologues) {
      $orthologues = $orthologue_list->{ucfirst $species} || {};
      $species_name = ucfirst $species;
    }

    if($group eq 'bacteria'){
      $group = 'archaea' if $self->is_archaea(lc $species);
    } elsif (!$is_pan){ 
      # not the pan compara page - generate groups
      $group = $species_defs->get_config($species_name, 'SPECIES_GROUP') || $spsites->{lc($species_name)} || 'Undefined';

      if(!exists $species_sets->{$group}){
        $species_sets->{$group} = {'title' => ucfirst $group, 'species' => [], 'all' => 0};
        push @$set_order, $group;
      }
    }

    if (!$orthologue_list->{$species_name} && $species_name ne $self->hub->species) {
      $no_ortho = 1;
    }

    foreach my $stable_id (keys %$orthologues) {
      my $orth_info = $orthologue_list->{$species_name}->{$stable_id};
      my $orth_desc = ucfirst($orth_info->{'homology_desc'});
      $orth_type->{$species_name}{$orth_desc} = 1;
    }

    if ($species_name ne $self->hub->species && !$orth_type->{$species_name}{'1-to-1'} && !$orth_type->{$species_name}{'1-to-many'}
          && !$orth_type->{$species_name}{'Many-to-many'}) {
      $no_ortho = 1;
    }

    foreach my $ss_name ('all', $group) {
      push @{$species_sets->{$ss_name}{'species'}}, $species_name;
      push (@$sets, $ss_name) if exists $species_sets->{$ss_name};

      while (my ($k, $v) = each (%{$orth_type->{$species_name}})) {
        $species_sets->{$ss_name}{$k} += $v;
      }

      $species_sets->{$ss_name}{'none'}++ if $no_ortho;
      $species_sets->{$ss_name}{'all'}++ if $species_name ne $self->hub->species;
    }
    
    $sets_by_species->{$species_name} = $sets;
  }

  if(!$is_pan) {
    my @unorder = @$set_order;
    @$set_order = sort(@unorder);
    unshift(@$set_order, 'all');
  }

  return ($species_sets, $sets_by_species, $set_order);
}

# Override this method from ensembl webcode as there is no collection-default type in EG databases.
# So checking for collection-[EG_DIVISION] type e.g. collection-fungi, collection-metazoa.
# However, bacteria currently returns only one type called collection-pan. So might need to change this in the future. Will leave it as it is for now, since nothing breaks.
sub _get_all_analysed_species {
  my ($self, $cdb) = @_;

  if (!$self->{'_all_analysed_species'}) {
    $self->{"_mlss_adaptor_$cdb"} ||= $self->hub->get_adaptor('get_MethodLinkSpeciesSetAdaptor', $cdb);

    my $pt_mlsss = $self->{"_mlss_adaptor_$cdb"}->fetch_all_by_method_link_type('PROTEIN_TREES');
    my $best_pt_mlss;

    if (scalar(@$pt_mlsss) > 1) {
      my $collection_name = "collection-" . $self->hub->species_defs->EG_DIVISION;

      ($best_pt_mlss) = grep {$_->species_set->name eq $collection_name} @$pt_mlsss;
    } else {
      $best_pt_mlss = $pt_mlsss->[0];
    }

    $self->{'_all_analysed_species'} = {map {$self->hub->species_defs->production_name_mapping($_->name) => 1} @{$best_pt_mlss->species_set->genome_dbs}};
  }

  return %{$self->{'_all_analysed_species'}};
}

# Override this method from ensembl webcode due to inconsistencies in what is used as species name in %not_seen hash.
# However, $sets_by_species uses only species url, so first letter needs to be in caps.
sub get_no_ortho_species_html {
  my ($self, $not_seen, $sets_by_species) = @_;
  my $hub = $self->hub;
  my $no_ortho_species_html = '';

  foreach (keys %$not_seen) {
    if ($sets_by_species->{ucfirst $_}) {
      $no_ortho_species_html .= '<li class="'. join(' ', @{$sets_by_species->{ucfirst $_}}) .'">'. $hub->species_defs->species_label($_) .'</li>';
    }
  }

  return $no_ortho_species_html;
}

sub in_archaea {
  my ($self, $species)=@_;
  
}

1;
