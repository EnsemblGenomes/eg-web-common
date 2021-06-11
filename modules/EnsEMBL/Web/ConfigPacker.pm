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

package EnsEMBL::Web::ConfigPacker;
use strict;
use warnings;
no warnings qw(uninitialized);

use LWP::UserAgent;

use previous qw(munge_config_tree);

sub munge_config_tree {
  my $self = shift;
  $self->PREV::munge_config_tree(@_);
  $self->_configure_external_resources;
}

sub _intraspecies_sql {
## need to exclude HOMOEOLOGUES as well as PARALOGUES otherwise too many method link species sets that prevents web site from starting
  return qq(
    select mls.species_set_id, mls.method_link_species_set_id, count(*) as count
      from method_link_species_set as mls, 
        method_link as ml, species_set as ss, genome_db as gd 
      where mls.species_set_id = ss.species_set_id
        and ss.genome_db_id = gd.genome_db_id 
        and mls.method_link_id = ml.method_link_id
        and ml.type not like "%PARALOGUES"
        and ml.type not like "%HOMOEOLOGUES"
        and mls.source != "ucsc"
      group by mls.method_link_species_set_id, mls.method_link_id
      having count = 1
  );
}

sub _homologies_sql {
## need to exclude HOMOEOLOGUES as well as PARALOGUES otherwise too many method link species sets that prevents web site from starting
  return qq(
    select ml.type, gd.name, gd.name, count(*) as count
      from method_link_species_set as mls, method_link as ml, species_set as ss, genome_db as gd 
      where mls.species_set_id = ss.species_set_id and
        ss.genome_db_id = gd.genome_db_id and
        mls.method_link_id = ml.method_link_id and
        ml.type not like '%PARALOGUES'
        and ml.type not like "%HOMOEOLOGUES"
      group by mls.method_link_species_set_id, mls.method_link_id
      having count = 1
  );
}

sub _summarise_pan_compara {
  my ($self, $dbh) = @_;

  ## Get info about pan-compara species
  my $metadata_db = $self->full_tree->{MULTI}->{databases}->{DATABASE_METADATA};
  my $meta_dbh = $self->db_connect('DATABASE_METADATA', $metadata_db);
  my $version = $SiteDefs::ENSEMBL_VERSION;
  my $aref = $meta_dbh->selectall_arrayref(
      "select 
          o.name, o.url_name, o.display_name, o.scientific_name, d.name 
        from 
          organism as o, genome as g, data_release as r, division as d 
        where 
          o.organism_id = g.organism_id 
          and g.data_release_id = r.data_release_id 
          and g.division_id = d.division_id
          and g.has_pan_compara = 1
          and r.ensembl_version = $version"
      );    
  ## Also get info about Archaea from pan-compara itself, for bacteria
  my $archaea = {};
  my $bref = $dbh->selectall_arrayref(
          "select 
            g.name from ncbi_taxa_node a 
          join 
            ncbi_taxa_name an using (taxon_id) 
          join 
            ncbi_taxa_node c on (c.left_index>a.left_index and c.right_index<a.right_index) 
          join 
            genome_db g on (g.taxon_id=c.taxon_id) 
          where 
            an.name='Archaea' 
            and an.name_class='scientific name'
  ");
  $archaea->{$_->[0]} = 1 for @$bref;

  foreach my $row (@$aref) {
    my ($prod_name, $url, $display_name, $sci_name, $division) = @$row;
    $division =~ s/Ensembl//;
    my $subdivision;
    if ($division eq 'Bacteria') {
      $subdivision = 'archaea' if $archaea->{$prod_name};
    }
    $self->db_tree->{'PAN_COMPARA_LOOKUP'}{$prod_name} = {
                'species_url'     => $url,
                'display_name'    => $display_name,
                'scientific_name' => $sci_name,
                'division'        => lc $division,
                'subdivision'     => $subdivision,
    };
  }
}

sub _go_sql {
  return qq(
    SELECT o.ontology_id, o.name, t.accession, t.name 
    FROM term t 
    LEFT JOIN ontology o USING (ontology_id)  
    WHERE t.is_root > 0
    and t.is_obsolete = 0 
    AND o.name NOT IN ('OGMS', 'CHEBI', 'PR', 'PBO', 'SO', 'BTO', 'UO', 'UNKNOWN', 'CL', 'PCO')
    AND NOT (o.name = 'PHI' AND t.accession != 'PHI:0')
    ORDER BY o.ontology_id
  );
}

sub _configure_external_resources {
  my $self = shift;
  my $species = $self->species;

  my $registry = $self->tree->{'FILE_REGISTRY_URL'} || ( warn "No FILE_REGISTRY_URL in config tree" && return );
  my $taxid = $self->tree($species)->{'TAXONOMY_ID'};

  # Registry parsing is lazy so re-use the parser between species'

  if ($taxid) {
    my $url = $registry . '/restapi/resources?taxid='.$taxid;
    my $ua = LWP::UserAgent->new;
 
    my $response = $ua->get($url);
    if ($response->is_success) {
      if (my $sources = decode_json($response->content)) {
        if ($sources->{'total'}) {
          foreach my $src (@{$sources->{'sources'} || []}) {
            my $source  = {
                            source_name    => $src->{title},
                            description => $src->{desc},
                            source_url => $src->{url},
                          };

            foreach my $k (keys %$src) {
              $source->{$k} = $src->{$k};
            }
          
            $source->{'menu_name'} ||= 'External data';
            $source->{'menu_key'} ||= lc($source->{'menu_name'});
            $source->{'menu_key'} =~ s/ /_/g;
          
            if ($source->{'submenu_name'}) {
              $source->{'submenu_key'} ||= lc($source->{'submenu_name'});
              $source->{'submenu_key'} =~ s/ /_/g;
            }
          
            unless ($source->{'name'}) {
              ($source->{'name'} = $src->{'title'}) =~ s/\s/\_/g;
            }

            my $type = 'BAM';
            $self->tree->{'ENSEMBL_INTERNAL_'.$type.'_SOURCES'}{$source->{'name'}} = $source;
          }
        }
      }
    }
  }
}

1;
