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

sub _species_sets {
## Group species into sets - separate method so it can be pluggable easily
  my ($self, $orthologue_list, $skipped, $orthologue_map, $cdb) = @_;
  
  my $hub           = $self->hub;
  my $species_defs  = $self->hub->species_defs;
  my %all_analysed_species = $self->_get_all_analysed_species($cdb);
  my $set_order     = [];
  my $lookup        = $hub->species_defs->prodnames_to_urls_lookup;
  my $pan_lookup    = {};
  my $is_pan        = $cdb =~/compara_pan_ensembl/;

  if ($is_pan) {
    $set_order = [qw(all vertebrates metazoa plants fungi protists bacteria archaea)];
    $pan_lookup  = $species_defs->multi_val('PAN_COMPARA_LOOKUP');
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

  my $lookup = $species_defs->prodnames_to_urls_lookup;
  foreach my $prod_name (keys %all_analysed_species) {

    my $species;
    if ($is_pan) {
      $species = $pan_lookup->{$prod_name}{'species_url'};
    }
    else {
      $species = $lookup->{$prod_name};
    }

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
      $group = $pan_lookup->{$prod_name}{'subdivision'} ? $pan_lookup->{$prod_name}{'subdivision'} : $pan_lookup->{$prod_name}{'division'};
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

# Override this method from ensembl webcode as historically there was no collection-default type in EG databases.
# Hence also checks for collection-[EG_DIVISION] type e.g. collection-fungi, collection-metazoa.
# N.B. bacteria currently returns only one type called collection-pan. So might need to change this in the future. Will leave it as it is for now, since nothing breaks.
sub _get_all_analysed_species {
  my ($self, $cdb) = @_;

  if (!$self->{'_all_analysed_species'}) {
    $self->{"_mlss_adaptor_$cdb"} ||= $self->hub->get_adaptor('get_MethodLinkSpeciesSetAdaptor', $cdb);

    my $pt_mlsss = $self->{"_mlss_adaptor_$cdb"}->fetch_all_by_method_link_type('PROTEIN_TREES');
    my $best_pt_mlss;

    if (scalar(@$pt_mlsss) > 1) {
      foreach (@$pt_mlsss) {
        if ($_->species_set->name eq 'collection-default' || $_->species_set->name eq "collection-" . $self->hub->species_defs->EG_DIVISION) {
          $best_pt_mlss = $_;
          last;
        }
      }
    } else {
      $best_pt_mlss = $pt_mlsss->[0];
    }

    $self->{'_all_analysed_species'} = {map {$_->name => 1} @{$best_pt_mlss->species_set->genome_dbs}};
  }

  return %{$self->{'_all_analysed_species'}};
}

# Override this method from ensembl webcode due to inconsistencies in what is used as species name in %not_seen hash.
# However, $sets_by_species uses only species url
sub get_no_ortho_species_html {
  my ($self, $not_seen, $sets_by_species) = @_;
  my $hub = $self->hub;
  my $no_ortho_species_html = '';
  my $lookup = $hub->species_defs->prodnames_to_urls_lookup;

  foreach (sort {lc $a cmp lc $b} keys %$not_seen) {
    my $sp_url = $lookup->{$_};
    if ($sets_by_species->{$sp_url}) {
      $no_ortho_species_html .= '<li class="'. join(' ', @{$sets_by_species->{$sp_url}}) .'">'. $hub->species_defs->species_label($sp_url) .'</li>';
    }
  }

  return $no_ortho_species_html;
}

1;
