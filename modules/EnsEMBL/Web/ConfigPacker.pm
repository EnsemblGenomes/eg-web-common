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
use JSON;
use Data::Dumper;

use Bio::EnsEMBL::Utils::MetaData::DBSQL::GenomeInfoAdaptor;

use previous qw(munge_config_tree);

sub munge_config_tree {
  my $self = shift;
  $self->PREV::munge_config_tree(@_);
  $self->_configure_external_resources;
}

## EG MULTI
sub _summarise_generic {
  my( $self, $db_name, $dbh ) = @_;

  my $t_aref = $dbh->selectall_arrayref( 'show table status' );
#---------- Table existance and row counts
  foreach my $row ( @$t_aref ) {
    $self->db_details($db_name)->{'tables'}{$row->[0]}{'rows'} = $row->[4];
  }
#---------- Meta coord system table...
  if( $self->_table_exists( $db_name, 'meta_coord' )) {
    $t_aref = $dbh->selectall_arrayref(
      'select table_name,max_length
         from meta_coord'
    );
    foreach my $row ( @$t_aref ) {
      $self->db_details($db_name)->{'tables'}{$row->[0]}{'coord_systems'}{$row->[1]}=$row->[2];
    }
  }
#---------- Meta table (everything except patches)
## Needs tweaking to work with new ensembl_ontology_xx db, which has no species_id in meta table
  if( $self->_table_exists( $db_name, 'meta' ) ) {
    my $hash = {};

## EG MULTI
# With multi species DB there is no way to define the list of chromosomes for the karyotype in the ini file
# The idea is the people who produce the DB can define the lists in the meta table using region.toplevel met key
# In case there is no such definition of the karyotype - we just create the lists of toplevel regions 
    if($db_name =~ /CORE/) {
      if ($self->is_collection('DATABASE_CORE')) {
        my $t_aref = $dbh->selectall_arrayref(
          qq{SELECT cs.species_id, s.name FROM seq_region s, coord_system cs
          WHERE s.coord_system_id = cs.coord_system_id AND cs.attrib = 'default_version' AND cs.name IN ('plasmid', 'chromosome')
          ORDER BY cs.species_id, s.name, s.seq_region_id}
        );

        foreach my $row ( @$t_aref ) {
            push @{$hash->{$row->[0]}{'region.toplevel'}}, $row->[1];
        }
     }
   }
##
    $t_aref  = $dbh->selectall_arrayref(
      'select meta_key,meta_value,meta_id, species_id
         from meta
        where meta_key != "patch"
        order by meta_key, meta_id'
    );

    foreach my $r( @$t_aref) {
      push @{ $hash->{$r->[3]+0}{$r->[0]}}, $r->[1];
    }
    $self->db_details($db_name)->{'meta_info'} = $hash;
  }
}

## EG : need to exclude HOMOEOLOGUES as well as PARALOGUES otherwise too many method link species sets that prevents web site from starting
sub _summarise_compara_db {
  my ($self, $code, $db_name) = @_;

  my $dbh = $self->db_connect($db_name);
  return unless $dbh;
  
  push @{$self->db_tree->{'compara_like_databases'}}, $db_name;

  $self->_summarise_generic($db_name, $dbh);
  
## EG - exclude HOMOEOLOGUES
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
##

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
  # Check if contains a species not in vega - use to determine whether or not to run vega specific queries
  my $vega = 1;
  
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
    
    $vega = 0 if $species eq 'Ailuropoda_melanoleuca';
 
    if ($intra_species{$species_set_id}) {
      $intra_species_constraints{$species}{$_} = 1 for keys %{$intra_species{$species_set_id}};
    }
    
    $species =~ tr/ /_/;
   
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
  #$self->_summarise_compara_alignments($dbh, $db_name, $vega ? undef : \%intra_species_constraints) if scalar keys %intra_species_constraints;
##
  
  my %sections = (
    ENSEMBL_ORTHOLOGUES => 'GENE',
    HOMOLOGOUS_GENE     => 'GENE',
    HOMOLOGOUS          => 'GENE',
  );
  
  # We've done the DB hash... So lets get on with the DNA, SYNTENY and GENE hashes;
  unless ($self->is_bacteria) {
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
    my ($species1, $species2) = (ucfirst $row->[1], ucfirst $row->[2]);
    
    $species1 =~ tr/ /_/;
    $species2 =~ tr/ /_/;
    
    my $key = $sections{uc $row->[0]} || uc $row->[0];
    
    $self->db_tree->{$db_name}{$key}{$species1}{$species2} = $valid_species{$species2};
  }             
  
  ###################################################################
  ## Section for colouring and colapsing/hidding genes per species in the GeneTree View
  
  # The config for taxon-groups is in DEFAULTS.ini
  # Here, we only need to add the "special" set of low-coverage species
  $res_aref = $dbh->selectall_arrayref(q{SELECT genome_db_id FROM genome_db WHERE is_high_coverage = 0});
  $self->db_tree->{$db_name}{'SPECIES_SET'}{'LOWCOVERAGE'} = [map {$_->[0]} @$res_aref];

  ## End section about colouring and colapsing/hidding gene in the GeneTree View
  ###################################################################

  ###################################################################
  ## Cache MLSS for quick lookup in ImageConfig

  $self->_build_compara_default_aligns($dbh,$self->db_tree->{$db_name});
  $self->_build_compara_mlss($dbh,$self->db_tree->{$db_name});

  ##
  ###################################################################

  ###################################################################
  ## Section for storing the genome_db_ids <=> species_name
  $res_aref = $dbh->selectall_arrayref('SELECT genome_db_id, name, assembly FROM genome_db');
  
  foreach my $row (@$res_aref) {
    my ($genome_db_id, $species_name) = @$row;
    
    $species_name =~ tr/ /_/;
    
    $self->db_tree->{$db_name}{'GENOME_DB'}{$species_name} = $genome_db_id;
    $self->db_tree->{$db_name}{'GENOME_DB'}{$genome_db_id} = $species_name;
  }
  ###################################################################
  
  ###################################################################
  ## Section for storing the taxa properties
  
  # Default name is the name stored in species_tree_node: the glyphset will use it by default

  # But a better name is the ensembl alias
  $res_aref = $dbh->selectall_arrayref(qq(SELECT taxon_id, name FROM ncbi_taxa_name WHERE name_class='ensembl alias name'));
  foreach my $row (@$res_aref) {
    my ($taxon_id, $taxon_name) = @$row;
    $self->db_tree->{$db_name}{'TAXON_NAME'}{$taxon_id} = $taxon_name;
  }

  # And we need the age of each ancestor
  $res_aref = $dbh->selectall_arrayref(qq(SELECT taxon_id, name FROM ncbi_taxa_name WHERE name_class='ensembl timetree mya'));
  foreach my $row (@$res_aref) {
    my ($taxon_id, $taxon_mya) = @$row;
    $self->db_tree->{$db_name}{'TAXON_MYA'}{$taxon_id} = $taxon_mya;
  }


  ###################################################################
  
  $dbh->disconnect;
}

## EG MULTI
# note: for MULTI need to use $self->tree($species)->{} instead of $self->tree->{$species}->
# To make use of the new meta key species.biomart_dataset
sub _munge_meta {
  my $self = shift;
  
  ##########################################
  # SPECIES_COMMON_NAME     = Human        #
  # SPECIES_PRODUCTION_NAME = homo_sapiens #
  # SPECIES_SCIENTIFIC_NAME = Homo sapiens #
  ##########################################

  my %keys = qw(
    species.taxonomy_id           TAXONOMY_ID
    species.url                   SPECIES_URL
    species.display_name          SPECIES_COMMON_NAME
    species.common_name           SPECIES_USUAL_NAME
    species.production_name       SPECIES_PRODUCTION_NAME
    species.scientific_name       SPECIES_SCIENTIFIC_NAME
    assembly.accession            ASSEMBLY_ACCESSION
    assembly.web_accession_source ASSEMBLY_ACCESSION_SOURCE
    assembly.web_accession_type   ASSEMBLY_ACCESSION_TYPE
    assembly.default              ASSEMBLY_NAME
    assembly.name                 ASSEMBLY_DISPLAY_NAME
    liftover.mapping              ASSEMBLY_MAPPINGS
    genebuild.method              GENEBUILD_METHOD
    genebuild.version             GENEBUILD_VERSION
    provider.name                 PROVIDER_NAME
    provider.url                  PROVIDER_URL
    provider.logo                 PROVIDER_LOGO
    species.strain                SPECIES_STRAIN
    species.sql_name              SYSTEM_NAME
    species.biomart_dataset       BIOMART_DATASET
    species.wikipedia_url         WIKIPEDIA_URL
    ploidy                        PLOIDY
  );
  
  my @months    = qw(blank Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
  my $meta_info = $self->_meta_info('DATABASE_CORE') || {};
  my @sp_count  = grep { $_ > 0 } keys %$meta_info;

  ## How many species in database?
  $self->tree->{'SPP_IN_DB'} = scalar @sp_count;
    
## EG   
  if ($self->is_collection('DATABASE_CORE')) {
##    
    if ($meta_info->{0}{'species.group'}) {
      $self->tree->{'DISPLAY_NAME'} = $meta_info->{0}{'species.group'};
    } else {
      (my $group_name = $self->{'_species'}) =~ s/_collection//;
      $self->tree->{'DISPLAY_NAME'} = $group_name;
    }
  } else {
    $self->tree->{'DISPLAY_NAME'} = $meta_info->{1}{'species.display_name'}[0];
  }

  while (my ($species_id, $meta_hash) = each (%$meta_info)) {
    next unless $species_id && $meta_hash && ref($meta_hash) eq 'HASH';

## EG do not use species url    
   # my $species = $meta_hash->{'species.url'}[0] || ucfirst $meta_hash->{'species.production_name'}[0]; 
   my $species = ucfirst $meta_hash->{'species.production_name'}[0];
##
    my $bio_name = $meta_hash->{'species.scientific_name'}[0];
    
    ## Put other meta info into variables
    while (my ($meta_key, $key) = each (%keys)) {
      next unless $meta_hash->{$meta_key};
      
      my $value = scalar @{$meta_hash->{$meta_key}} > 1 ? $meta_hash->{$meta_key} : $meta_hash->{$meta_key}[0]; 

      ## Set version of assembly name that we can use where space is limited 
      if ($meta_key eq 'assembly.name') {
        $self->tree($species)->{'ASSEMBLY_SHORT_NAME'} = (length($value) > 16)
                  ? $self->db_tree->{'ASSEMBLY_VERSION'} : $value;
      }

      $self->tree($species)->{$key} = $value;
    }

    ## Do species group
    my $taxonomy = $meta_hash->{'species.classification'};
    
    if ($taxonomy && scalar(@$taxonomy)) {
      my %valid_taxa = map {$_ => 1} @{ $self->tree->{'TAXON_ORDER'} };
      my @matched_groups = grep {$valid_taxa{$_}} @$taxonomy;
      $self->tree($species)->{'SPECIES_GROUP'} = $matched_groups[0] if @matched_groups;
      $self->tree($species)->{'SPECIES_GROUP_HIERARCHY'} = \@matched_groups;
    }

    ## create lookup hash for species aliases
    foreach my $alias (@{$meta_hash->{'species.alias'}}) {
      $self->full_tree->{'MULTI'}{'SPECIES_ALIASES'}{$alias} = $species;
    }

    ## Backwards compatibility
    $self->tree($species)->{'SPECIES_BIO_NAME'}  = $bio_name;
    ## Used mainly in <head> links
    ($self->tree($species)->{'SPECIES_BIO_SHORT'} = $bio_name) =~ s/^([A-Z])[a-z]+_([a-z]+)$/$1.$2/;

    #if ($self->tree->{'ENSEMBL_SPECIES'}) {
      push @{$self->tree->{'DB_SPECIES'}}, $species;
    #} else {
    #  $self->tree->{'DB_SPECIES'} = [ $species ];
    #}

    
    $self->tree($species)->{'SPECIES_META_ID'} = $species_id;

    ## Munge genebuild info
    my @A = split '-', $meta_hash->{'genebuild.start_date'}[0];
    
    $self->tree($species)->{'GENEBUILD_START'} = $A[1] ? "$months[$A[1]] $A[0]" : undef;
    $self->tree($species)->{'GENEBUILD_BY'}    = $A[2];

    @A = split '-', $meta_hash->{'genebuild.initial_release_date'}[0];
    
    $self->tree($species)->{'GENEBUILD_RELEASE'} = $A[1] ? "$months[$A[1]] $A[0]" : undef;
    
    @A = split '-', $meta_hash->{'genebuild.last_geneset_update'}[0];

    $self->tree($species)->{'GENEBUILD_LATEST'} = $A[1] ? "$months[$A[1]] $A[0]" : undef;
    
    @A = split '-', $meta_hash->{'assembly.date'}[0];
    
    $self->tree($species)->{'ASSEMBLY_DATE'} = $A[1] ? "$months[$A[1]] $A[0]" : undef;
    

    $self->tree($species)->{'HAVANA_DATAFREEZE_DATE'} = $meta_hash->{'genebuild.havana_datafreeze_date'}[0];

    # check if there are sample search entries defined in meta table ( the case with Ensembl Genomes)
    # they can be overwritten at a later stage  via INI files
    my @ks = grep { /^sample\./ } keys %{$meta_hash || {}}; 
    my $shash;

    foreach my $k (@ks) {
      (my $k1 = $k) =~ s/^sample\.//;
      $shash->{uc $k1} = $meta_hash->{$k}->[0];
    }
    ## add in any missing values where text omitted because same as param
    while (my ($key, $value) = each (%$shash)) {
      next unless $key =~ /PARAM/;
      (my $type = $key) =~ s/_PARAM//;
      unless ($shash->{$type.'_TEXT'}) {
        $shash->{$type.'_TEXT'} = $value;
      } 
    }

    $self->tree($species)->{'SAMPLE_DATA'} = $shash if scalar keys %$shash;

    # check if the karyotype/list of toplevel regions ( normally chroosomes) is defined in meta table
    @{$self->tree($species)->{'TOPLEVEL_REGIONS'}} = @{$meta_hash->{'regions.toplevel'}} if $meta_hash->{'regions.toplevel'};

## EG    
    if ($self->is_collection('DATABASE_CORE')) {
      @{$self->tree($species)->{'ENSEMBL_CHROMOSOMES'}} = ();                                                                      #nickl: need to explicitly define as empty array by default otherwise SpeciesDefs looks for a value at collection level
      @{$self->tree($species)->{'ENSEMBL_CHROMOSOMES'}} = @{$meta_hash->{'region.toplevel'}} if $meta_hash->{'region.toplevel'};
    }
##

    #If the top level regions are other than palsmid or chromosome, ENSEMBL_CHROMOSOMES is set to an empty array
    #in order to disable the 'Karyotype' and 'Chromosome summary' links in the menu tree
    if ($meta_hash->{'region.toplevel'}) {

      my $db_name = 'DATABASE_CORE';
      my $dbh     = $self->db_connect($db_name);

      #it's sufficient to check just the first elem, assuming the list doesn't contain a mixture of plasmid/chromosome and other than plasmid/chromosome regions:
      my $sname  = $meta_hash->{'region.toplevel'}->[0];
      my $t_aref = $dbh->selectall_arrayref(
        "select       
        coord_system.name, 
        seq_region.name
        from 
        meta, 
        coord_system, 
        seq_region, 
        seq_region_attrib
        where 
        coord_system.coord_system_id = seq_region.coord_system_id
        and seq_region_attrib.seq_region_id = seq_region.seq_region_id
        and seq_region_attrib.attrib_type_id =  (SELECT attrib_type_id FROM attrib_type where name = 'Top Level') 
        and meta.species_id=coord_system.species_id 
        and meta.meta_key = 'species.production_name'
        and meta.meta_value = '" . $species . "'
        and seq_region.name = '" . $sname . "'
        and coord_system.name not in ('plasmid', 'chromosome')"
      ) || [];

      if (@$t_aref) {
        @{$self->tree($species)->{'ENSEMBL_CHROMOSOMES'}} = ();
      }
    }


    (my $group_name = $self->{'_species'}) =~ s/_collection//;
    $self->tree($species)->{'SPECIES_DATASET'} = $group_name;
    
    # convenience flag to determine if species is polyploidy
    $self->tree($species)->{POLYPLOIDY} = ($self->tree($species)->{PLOIDY} > 2);

    #  munge EG genome info 
    my $metadata_db = $self->full_tree->{MULTI}->{databases}->{DATABASE_METADATA};

    if ($metadata_db) {
      my $dbc = Bio::EnsEMBL::DBSQL::DBConnection->new(
        -USER   => $metadata_db->{USER},
        -PASS   => $metadata_db->{PASS},
        -PORT   => $metadata_db->{PORT},
        -HOST   => $metadata_db->{HOST},
        -DBNAME => $metadata_db->{NAME}
      );

      my $genome_info_adaptor = Bio::EnsEMBL::Utils::MetaData::DBSQL::GenomeInfoAdaptor->new(-DBC => $dbc);
      
      if ($genome_info_adaptor) {
        my $dbname = $self->tree->{databases}->{DATABASE_CORE}->{NAME};
        foreach my $genome (@{ $genome_info_adaptor->fetch_all_by_dbname($dbname) }) {
          my $species = $genome->species;
          $self->tree($species)->{'SEROTYPE'}     = $genome->serotype;
          $self->tree($species)->{'PUBLICATIONS'} = $genome->publications;
        }
      }
    } 
  }
}

# To get the available relations
sub _summarise_go_db {
  my $self = shift;
  my $db_name = 'DATABASE_GO';
  my $dbh     = $self->db_connect( $db_name );
  return unless $dbh;
  #$self->_summarise_generic( $db_name, $dbh );
  # get the list of the available ontologies and skip the ontologies we do not use
  my $t_aref = $dbh->selectall_arrayref(
"select o.ontology_id, o.namespace, o.name, t.accession, t.name 
   from term t 
     left join ontology o using (ontology_id)  
       where t.is_root > 0 and 
             o.name not in ('OGMS', 'CHEBI', 'PR', 'PBO', 'SO', 'BTO', 'UO', 'UNKNOWN', 'CL', 'PCO')
       order by o.name, o.namespace
");

  foreach my $row (@$t_aref) {
    my ($oid, $namespace, $ontology, $root_term, $description) = @$row;
    next unless ($ontology && $root_term);
    $oid =~ s/(-|\s)/_/g;
    $description =~ s/\s+$//; # hack to strip training whitespace
    $description =~ s/(-|\s)/_/g;
    $self->db_tree->{'ONTOLOGIES'}->{$oid} = {
      db => $ontology,
      root => $root_term,
      description => $description 
    };
  }

# # get the available relations
# #           qq{select t.ontology_id, rt.name from relation r
#   my $sql = qq{select o.namespace, rt.name from relation r
# left join relation_type rt using (relation_type_id)
# left join term t on child_term_id = term_id
# join ontology  o on o.ontology_id = t.ontology_id
# group by t.ontology_id, rt.name
# } ;
#   my $s_aref = $dbh->selectall_arrayref($sql);

#   foreach my $row (@$s_aref) {
#       my ($oid, $relation) = @$row;
#       $oid =~ s/(-|\s)/_/g;
#       next unless $self->db_tree->{'ONTOLOGIES'}->{$oid};
#       push @{$self->db_tree->{'ONTOLOGIES'}->{$oid}->{relations}}, $relation;
#   }

  $dbh->disconnect();
}

sub _configure_external_resources {
  my $self = shift;
  my $species = $self->species;

  my $registry = $self->tree->{'FILE_REGISTRY_URL'} || ( warn "No FILE_REGISTRY_URL in config tree" && return );
  my $taxid = $self->tree($species)->{'TAXONOMY_ID'};

#  warn " Configure files for $species ($taxid)...";

  # Registry parsing is lazy so re-use the parser between species'

  if ($taxid) {
      my $url = $registry . '/restapi/resources?taxid='.$taxid;
#      warn $url;
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

## EG
sub is_collection {
  my ($self, $db_name) = @_;
  my $database_name = $self->tree->{'databases'}->{'DATABASE_CORE'}{'NAME'};
  return $database_name =~ /_collection/;
}

sub is_bacteria {
  my ($self, $db_name) = @_;
  return $SiteDefs::ENSEMBL_SITETYPE =~ /bacteria/i
}
##

1;
