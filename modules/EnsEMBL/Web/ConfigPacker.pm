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

sub _summarise_compara_db {
  my ($self, $code, $db_name) = @_;
  
  my $dbh = $self->db_connect($db_name);
  return unless $dbh;
  
  push @{$self->db_tree->{'compara_like_databases'}}, $db_name;

  $self->_summarise_generic($db_name, $dbh);

  if ($code eq 'compara_pan_ensembl') {
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
 
## EG : need to exclude HOMOEOLOGUES as well as PARALOGUES otherwise too many method link species sets that prevents web site from starting
  # See if there are any intraspecies alignments (ie a self compara)
  my $intra_species_aref = $dbh->selectall_arrayref('
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
  ');
  
  my (%intra_species, %intra_species_constraints);
  $intra_species{$_->[0]}{$_->[1]} = 1 for @$intra_species_aref;
  
  # look at all the multiple alignments
  ## We've done the DB hash...So lets get on with the multiple alignment hash;
  my $res_aref = $dbh->selectall_arrayref('
    select ml.class, ml.type, gd.name, mlss.name, mlss.method_link_species_set_id, ss.species_set_id
      from method_link ml, 
        method_link_species_set mlss, 
        genome_db gd, species_set ss 
      where mlss.method_link_id = ml.method_link_id and
        mlss.species_set_id = ss.species_set_id and 
        ss.genome_db_id = gd.genome_db_id and
        (ml.class like "GenomicAlign%" or ml.class like "%.constrained_element" or ml.class = "ConservationScore.conservation_score")
  ');
  
  my $constrained_elements = {};
  my %valid_species = map { $_ => 1 } keys %{$self->full_tree};
  
  foreach my $row (@$res_aref) { 
    my ($class, $type, $species, $name, $id, $species_set_id) = ($row->[0], uc $row->[1], ucfirst $row->[2], $row->[3], $row->[4], $row->[5]);
    my $key = 'ALIGNMENTS';
    
    if ($class =~ /ConservationScore/ || $type =~ /CONSERVATION_SCORE/) {
      $key  = 'CONSERVATION_SCORES';
      $name = 'Conservation scores';
    } elsif ($class =~ /constrained_element/ || $type =~ /CONSTRAINED_ELEMENT/) {
      $key = 'CONSTRAINED_ELEMENTS';
      $constrained_elements->{$species_set_id} = $id;
    } elsif ($type !~ /EPO_LOW_COVERAGE/ && ($class =~ /tree_alignment/ || $type  =~ /EPO/)) {
      $self->db_tree->{$db_name}{$key}{$id}{'species'}{'ancestral_sequences'} = 1 unless exists $self->db_tree->{$db_name}{$key}{$id};
    }
    
    
    if ($intra_species{$species_set_id}) {
      $intra_species_constraints{$species}{$_} = 1 for keys %{$intra_species{$species_set_id}};
    }
    
    $self->db_tree->{$db_name}{$key}{$id}{'id'}                = $id;
    $self->db_tree->{$db_name}{$key}{$id}{'name'}              = $name;
    $self->db_tree->{$db_name}{$key}{$id}{'type'}              = $type;
    $self->db_tree->{$db_name}{$key}{$id}{'class'}             = $class;
    $self->db_tree->{$db_name}{$key}{$id}{'species_set_id'}    = $species_set_id;
    $self->db_tree->{$db_name}{$key}{$id}{'species'}{$species} = 1;
  }
  
  foreach my $species_set_id (keys %$constrained_elements) {
    my $constr_elem_id = $constrained_elements->{$species_set_id};
    
    foreach my $id (keys %{$self->db_tree->{$db_name}{'ALIGNMENTS'}}) {
      $self->db_tree->{$db_name}{'ALIGNMENTS'}{$id}{'constrained_element'} = $constr_elem_id if $self->db_tree->{$db_name}{'ALIGNMENTS'}{$id}{'species_set_id'} == $species_set_id;
    }
  }

  $res_aref = $dbh->selectall_arrayref('SELECT method_link_species_set_id, value FROM method_link_species_set_tag JOIN method_link_species_set USING (method_link_species_set_id) JOIN method_link USING (method_link_id) WHERE type LIKE "%CONSERVATION\_SCORE" AND tag = "msa_mlss_id"');
  
  foreach my $row (@$res_aref) {
    my ($conservation_score_id, $alignment_id) = ($row->[0], $row->[1]);
    
    next unless $conservation_score_id;
    
    $self->db_tree->{$db_name}{'ALIGNMENTS'}{$alignment_id}{'conservation_score'} = $conservation_score_id;
  }

## EG - now done on the fly - too many alignments to put in configs 
  # if there are intraspecies alignments then get full details of genomic alignments, ie start and stop, constrained by a set defined above (or no constraint for all alignments)
##
  
  my %sections = (
    ENSEMBL_ORTHOLOGUES => 'GENE',
    HOMOLOGOUS_GENE     => 'GENE',
    HOMOLOGOUS          => 'GENE',
  );
  
  # We've done the DB hash... So lets get on with the DNA, SYNTENY and GENE hashes;
  unless ($SiteDefs::EG_DIVISION eq 'bacteria') {
    $res_aref = $dbh->selectall_arrayref('
      select ml.type, gd1.name, gd2.name
        from genome_db gd1, genome_db gd2, species_set ss1, species_set ss2,
         method_link ml, method_link_species_set mls1,
         method_link_species_set mls2
       where mls1.method_link_species_set_id = mls2.method_link_species_set_id and
         ml.method_link_id = mls1.method_link_id and
         ml.method_link_id = mls2.method_link_id and
         gd1.genome_db_id != gd2.genome_db_id and
         mls1.species_set_id = ss1.species_set_id and
         mls2.species_set_id = ss2.species_set_id and
         ss1.genome_db_id = gd1.genome_db_id and
         ss2.genome_db_id = gd2.genome_db_id
    ');
  }
  
  ## That's the end of the compara region munging!

## EG - exclude HOMOEOLOGUES
  my $res_aref_2 = $dbh->selectall_arrayref(qq{
    select ml.type, gd.name, gd.name, count(*) as count
      from method_link_species_set as mls, method_link as ml, species_set as ss, genome_db as gd 
      where mls.species_set_id = ss.species_set_id and
        ss.genome_db_id = gd.genome_db_id and
        mls.method_link_id = ml.method_link_id and
        ml.type not like '%PARALOGUES'
        and ml.type not like "%HOMOEOLOGUES"
      group by mls.method_link_species_set_id, mls.method_link_id
      having count = 1
  });
##
  
  push @$res_aref, $_ for @$res_aref_2;
  
  foreach my $row (@$res_aref) {
    my $key = $sections{uc $row->[0]} || uc $row->[0];
    my ($species1, $species2) = ($row->[1], $row->[2]);
    $self->db_tree->{$db_name}{$key}{$species1}{$species2} = $valid_species{$species2};
  }             
  

  ###################################################################
  ## Cache MLSS for quick lookup in ImageConfig

  $self->_build_compara_default_aligns($dbh,$self->db_tree->{$db_name});
  $self->_build_compara_mlss($dbh,$self->db_tree->{$db_name});

  ##
  ###################################################################

  
  $dbh->disconnect;
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
