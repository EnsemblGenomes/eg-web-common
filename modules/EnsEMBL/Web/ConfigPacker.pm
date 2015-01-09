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

use LWP::UserAgent;
use JSON;
use Data::Dumper;

use previous qw(munge_config_tree _summarise_generic);

## EG - don't pack blast configs - instead generate on the fly, see E::W::SpeciesDefs::get_blast_datasources
sub _configure_blast {} 
##

sub munge_config_tree {
  my $self = shift;
  $self->PREV::munge_config_tree(@_);
  $self->_configure_external_resources;
}

sub _configure_external_resources {
  my $self = shift;
  my $species = $self->species;

  my $registry = $self->tree->{'FILE_REGISTRY_URL'} || ( warn "No FILE_REGISTRY_URL in config tree" && return );
  my $taxid = $self->tree->{$species}->{'TAXONOMY_ID'};

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
    
  if (scalar @sp_count > 1) {
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
    
    my $species  = ucfirst $meta_hash->{'species.production_name'}[0];
    my $bio_name = $meta_hash->{'species.scientific_name'}[0];
    
    ## Put other meta info into variables
    while (my ($meta_key, $key) = each (%keys)) {
      next unless $meta_hash->{$meta_key};
      
      my $value = scalar @{$meta_hash->{$meta_key}} > 1 ? $meta_hash->{$meta_key} : $meta_hash->{$meta_key}[0]; 
      $self->tree->{$species}{$key} = $value;
    }

    ## Do species group
    my $taxonomy = $meta_hash->{'species.classification'};
    
    if ($taxonomy && scalar(@$taxonomy)) {
      my $order = $self->tree->{'TAXON_ORDER'};
      
      foreach my $taxon (@$taxonomy) {
        foreach my $group (@$order) {
          if ($taxon eq $group) {
            $self->tree->{$species}{'SPECIES_GROUP'} = $group;
            last;
          }
        }
        
        last if $self->tree->{$species}{'SPECIES_GROUP'};
      }
    }

    ## create lookup hash for species aliases
    foreach my $alias (@{$meta_hash->{'species.alias'}}) {
      $self->full_tree->{'MULTI'}{'SPECIES_ALIASES'}{$alias} = $species;
    }

    ## Backwards compatibility
    $self->tree->{$species}{'SPECIES_BIO_NAME'}  = $bio_name;
    ## Used mainly in <head> links
    ($self->tree->{$species}{'SPECIES_BIO_SHORT'} = $bio_name) =~ s/^([A-Z])[a-z]+_([a-z]+)$/$1.$2/;
    
    if ($self->tree->{'ENSEMBL_SPECIES'}) {
      push @{$self->tree->{'DB_SPECIES'}}, $species;
    } else {
      $self->tree->{'DB_SPECIES'} = [ $species ];
    }

    
    $self->tree->{$species}{'SPECIES_META_ID'} = $species_id;

    ## Munge genebuild info
    my @A = split '-', $meta_hash->{'genebuild.start_date'}[0];
    
    $self->tree->{$species}{'GENEBUILD_START'} = $A[1] ? "$months[$A[1]] $A[0]" : undef;
    $self->tree->{$species}{'GENEBUILD_BY'}    = $A[2];

    @A = split '-', $meta_hash->{'genebuild.initial_release_date'}[0];
    
    $self->tree->{$species}{'GENEBUILD_RELEASE'} = $A[1] ? "$months[$A[1]] $A[0]" : undef;
    
    @A = split '-', $meta_hash->{'genebuild.last_geneset_update'}[0];

    $self->tree->{$species}{'GENEBUILD_LATEST'} = $A[1] ? "$months[$A[1]] $A[0]" : undef;
    
    @A = split '-', $meta_hash->{'assembly.date'}[0];
    
    $self->tree->{$species}{'ASSEMBLY_DATE'} = $A[1] ? "$months[$A[1]] $A[0]" : undef;
    

    $self->tree->{$species}{'HAVANA_DATAFREEZE_DATE'} = $meta_hash->{'genebuild.havana_datafreeze_date'}[0];

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

    $self->tree->{$species}{'SAMPLE_DATA'} = $shash if scalar keys %$shash;

    # check if the karyotype/list of toplevel regions ( normally chroosomes) is defined in meta table
    @{$self->tree($species)->{'TOPLEVEL_REGIONS'}} = @{$meta_hash->{'regions.toplevel'}} if $meta_hash->{'regions.toplevel'};
    
    # convenience flag to determine if species is polyploidy
    $self->tree->{$species}{POLYPLOIDY} = ($self->tree->{$species}{PLOIDY} > 2);
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
"select o.namespace, o.name, t.accession, t.name 
   from term t 
     left join ontology o using (ontology_id)  
       where t.is_root > 0 and 
             o.name not in ('OGMS', 'CHEBI', 'PR', 'PBO', 'SO', 'BTO', 'UO', 'UNKNOWN', 'CL', 'PCO')
       order by o.name, o.namespace
");

  foreach my $row (@$t_aref) {
    my ($oid, $ontology, $root_term, $description) = @$row;
    next unless ($ontology && $root_term);
    $oid =~ s/(-|\s)/_/g;
    $self->db_tree->{'ONTOLOGIES'}->{$oid} = {
      db => $ontology,
      root => $root_term,
      description => $description
    };
  }

# get the available relations
#           qq{select t.ontology_id, rt.name from relation r
  my $sql = qq{select o.namespace, rt.name from relation r
left join relation_type rt using (relation_type_id)
left join term t on child_term_id = term_id
join ontology  o on o.ontology_id = t.ontology_id
group by t.ontology_id, rt.name
} ;
  my $s_aref = $dbh->selectall_arrayref($sql);

  foreach my $row (@$s_aref) {
      my ($oid, $relation) = @$row;
      $oid =~ s/(-|\s)/_/g;
      next unless $self->db_tree->{'ONTOLOGIES'}->{$oid};
      push @{$self->db_tree->{'ONTOLOGIES'}->{$oid}->{relations}}, $relation;
  }

  $dbh->disconnect();
}


## EG : need to exclude HOMOEOLOGUES as well as PARALOGUES otherwise too many method link species sets that prevents web site from starting
sub _summarise_compara_db {
  my ($self, $code, $db_name) = @_;
  
  my $dbh = $self->db_connect($db_name);
  return unless $dbh;
  
  push @{$self->db_tree->{'compara_like_databases'}}, $db_name;

  $self->_summarise_generic($db_name, $dbh);
  
## EG
# added 
# and ml.type not like "%HOMOEOLOGUES"
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
## EG : this has to be 1 for wheat
    $vega = 0 if $species eq 'Triticum_aestivum';
    
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
  
  ## That's the end of the compara region munging!

## EG
# added 
# and ml.type not like "%HOMOEOLOGUES"

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
  # 1. Only use the species_sets that have a genetree_display tag
  
  $res_aref = $dbh->selectall_arrayref(q{SELECT species_set_id FROM species_set_tag WHERE tag = 'genetree_display'});
  
  foreach my $row (@$res_aref) {
    # 2.1 For each set, get all the tags
    my ($species_set_id) = @$row;
    my $res_aref2 = $dbh->selectall_arrayref("SELECT tag, value FROM species_set_tag WHERE species_set_id = $species_set_id");
    my $res;
    
    foreach my $row2 (@$res_aref2) {
      my ($tag, $value) = @$row2;
      $res->{$tag} = $value;
    }
    
    my $name = $res->{'name'}; # 2.2 Get the name for this set (required)
    
    next unless $name; # Requires a name for the species_set
    
    # 2.3 Store the values
    while (my ($key, $value) = each %$res) {
      next if $key eq 'name';
      $self->db_tree->{$db_name}{'SPECIES_SET'}{$name}{$key} = $value;
    }

    # 3. Get the genome_db_ids for each set
    $res_aref2 = $dbh->selectall_arrayref("SELECT genome_db_id FROM species_set WHERE species_set_id = $species_set_id");
    
    push @{$self->db_tree->{$db_name}{'SPECIES_SET'}{$name}{'genome_db_ids'}}, $_->[0] for @$res_aref2;
  }
  
  ## End section about colouring and colapsing/hidding gene in the GeneTree View
  ###################################################################

  ###################################################################
  ## Section for storing the genome_db_ids <=> species_name
  $res_aref = $dbh->selectall_arrayref('SELECT genome_db_id, name, assembly FROM genome_db WHERE assembly_default = 1');
  
  foreach my $row (@$res_aref) {
    my ($genome_db_id, $species_name) = @$row;
    
    $species_name =~ tr/ /_/;
    
    $self->db_tree->{$db_name}{'GENOME_DB'}{$species_name} = $genome_db_id;
    $self->db_tree->{$db_name}{'GENOME_DB'}{$genome_db_id} = $species_name;
  }
  ###################################################################
  
  ###################################################################
  ## Section for storing the taxa properties
  
  # Default name is the scientific name
  $res_aref = $dbh->selectall_arrayref(qq(SELECT DISTINCT taxon_id, name FROM ncbi_taxa_name JOIN gene_tree_node_tag ON taxon_id=value WHERE tag='lost_taxon_id' AND name_class='scientific name'));
  foreach my $row (@$res_aref) {
    my ($taxon_id, $taxon_name) = @$row;
    $self->db_tree->{$db_name}{'TAXON_NAME'}{$taxon_id} = $taxon_name;
  }

  # Better name is the ensembl alias
  $res_aref = $dbh->selectall_arrayref(qq(SELECT taxon_id, name FROM ncbi_taxa_name WHERE name_class='ensembl alias name'));
  foreach my $row (@$res_aref) {
    my ($taxon_id, $taxon_name) = @$row;
    $self->db_tree->{$db_name}{'TAXON_NAME'}{$taxon_id} = $taxon_name;
  }

  # And the age of each ancestor
  $res_aref = $dbh->selectall_arrayref(qq(SELECT taxon_id, name FROM ncbi_taxa_name WHERE name_class='ensembl timetree mya'));
  foreach my $row (@$res_aref) {
    my ($taxon_id, $taxon_mya) = @$row;
    $self->db_tree->{$db_name}{'TAXON_MYA'}{$taxon_id} = $taxon_mya;
  }


  ###################################################################
  
  $dbh->disconnect;
}

sub _summarise_core_tables {
  my $self   = shift;
  my $db_key = shift;
  my $db_name = shift; 
  my $dbh    = $self->db_connect( $db_name );

  return unless $dbh; 

  push @{ $self->db_tree->{'core_like_databases'} }, $db_name;

  $self->_summarise_generic( $db_name, $dbh );

## Get chromosomes in order (replacement for array in ini files)
## and also check for presence of LRGs
## Only need to do this once!
  if ($db_name eq 'DATABASE_CORE') {
    my $s_aref = $dbh->selectall_arrayref(
      'select s.name 
      from seq_region s, seq_region_attrib sa, attrib_type a 
      where sa.seq_region_id = s.seq_region_id 
        and sa.attrib_type_id = a.attrib_type_id 
        and a.code = "karyotype_rank" 
      order by abs(sa.value)'
    );
    my $chrs = [];
    foreach my $row (@$s_aref) {
      push @$chrs, $row->[0];
    }
    $self->db_tree->{'ENSEMBL_CHROMOSOMES'} = $chrs;
    $s_aref = $dbh->selectall_arrayref(
        'select count(*) from seq_region where name like "LRG%"'
    );
    if ($s_aref->[0][0] > 0) {
      $self->db_tree->{'HAS_LRG'} = 1;
    }
  }

##
## Grab each of the analyses - will use these in a moment...
##
  my $t_aref = $dbh->selectall_arrayref(
    'select a.analysis_id, lower(a.logic_name), a.created,
            ad.display_label, ad.description,
            ad.displayable, ad.web_data
       from analysis a left join analysis_description as ad on a.analysis_id=ad.analysis_id'
  );
  my $analysis = {};
  foreach my $a_aref (@$t_aref) { 
    ## Strip out "crap" at front and end! probably some q(')s...
    ( my $A = $a_aref->[6] ) =~ s/^[^{]+//;
    $A =~ s/[^}]+$//;
    my $T = eval($A);
    if (ref($T) ne 'HASH') {
      if ($A) {
        warn "Deleting web_data for $db_key:".$a_aref->[1].", check for syntax error";
      }
      $T = {};
    }
    $analysis->{ $a_aref->[0] } = {
      'logic_name'  => $a_aref->[1],
      'name'        => $a_aref->[3],
      'description' => $a_aref->[4],
      'displayable' => $a_aref->[5],
      'web_data'    => $T
    };
  }
  ## Set last repeat mask date whilst we're at it, as needed by BLAST configuration, below
  my $r_aref = $dbh->selectall_arrayref( 
      'select max(date_format( created, "%Y%m%d"))
      from analysis, meta
      where logic_name = lower(meta_value) and meta_key = "repeat.analysis"' 
  );
  my $date;
  foreach my $a_aref (@$r_aref){
    $date = $a_aref->[0];
  } 
  if ($date) { $self->db_tree->{'REPEAT_MASK_DATE'} = $date; } 

  #get website version the db was first released on - needed for Vega BLAST auto configuration
  (my $initial_release) = $dbh->selectrow_array(qq(SELECT meta_value FROM meta WHERE meta_key = 'initial_release.version'));
  if ($initial_release) { $self->db_tree->{'DB_RELEASE_VERSION'} = $initial_release; }

## 
## Let us get analysis information about each feature type...
##
  foreach my $table ( qw(
        dna_align_feature protein_align_feature simple_feature
        protein_feature marker_feature 
        repeat_feature ditag_feature
        transcript gene prediction_transcript unmapped_object
  )) { 
    my $res_aref = $dbh->selectall_arrayref(
      "select analysis_id,count(*) from $table group by analysis_id"
    );
    foreach my $T ( @$res_aref ) {
      my $a_ref = $analysis->{$T->[0]}
        || ( warn("Missing analysis entry $table - $T->[0]\n") && next );
      my $value = {
        'name'  => $a_ref->{'name'},
        'desc'  => $a_ref->{'description'},
        'disp'  => $a_ref->{'displayable'},
        'web'   => $a_ref->{'web_data'},
        'count' => $T->[1]
      };
      $self->db_details($db_name)->{'tables'}{$table}{'analyses'}{$a_ref->{'logic_name'}} = $value;
    }
  }

    my $df_aref = $dbh->selectall_arrayref(
      "select analysis_id,file_type from data_file group by analysis_id"
      );
  foreach my $T ( @$df_aref ) {
    my $a_ref = $analysis->{$T->[0]}
        || ( warn("Missing analysis entry data_file - $T->[0]\n") && next );
    my $value = {
        'name'    => $a_ref->{'name'},
        'desc'    => $a_ref->{'description'},
        'disp'    => $a_ref->{'displayable'},
        'web'     => $a_ref->{'web_data'},
        'count'   => 1,
        'format'  => lc($T->[1]),
    };
    $self->db_details($db_name)->{'tables'}{'data_file'}{'analyses'}{$a_ref->{'logic_name'}} = $value;
  }


#---------- Additional queries - by type...

#
# * Check to see if we have any interpro? - not sure why may drop...
#

#
# * Repeats
#
  $t_aref = $dbh->selectall_arrayref(
    'select rf.analysis_id,rc.repeat_type, count(*)
       from repeat_consensus as rc, repeat_feature as rf
      where rc.repeat_consensus_id = rf.repeat_consensus_id
      group by analysis_id, repeat_type'
  );
  foreach my $row (@$t_aref) {
    my $a_ref = $analysis->{$row->[0]};
    $self->db_details($db_name)->{'tables'}{'repeat_feature'}{'analyses'}{$a_ref->{'logic_name'}}{'types'}{$row->[1]} = $row->[2];
  }
#
# * Misc-sets
#
  $t_aref = $dbh->selectall_arrayref(
    'select ms.code, ms.name, ms.description, count(*) as N, ms.max_length
       from misc_set as ms, misc_feature_misc_set as mfms
      where mfms.misc_set_id = ms.misc_set_id
      group by ms.misc_set_id'
  );
  $self->db_details($db_name)->{'tables'}{'misc_feature'}{'sets'} = { map {
    ( $_->[0] => { 'name' => $_->[1], 'desc' => $_->[2], 'count' => $_->[3], 'max_length' => $_->[4] })
  } @$t_aref };

#
# * External-db
#
  my $sth = $dbh->prepare(qq(select * from external_db));
  $sth->execute;
  my $hashref;
  while ( my $t =  $sth->fetchrow_hashref) {
    $hashref->{$t->{'external_db_id'}} = $t;
  }
  $self->db_details($db_name)->{'tables'}{'external_db'}{'entries'} = $hashref;

#---------- Now for the core only ones.......

  if( $db_key eq 'core' ) {
#
# * Co-ordinate systems..
#

    my $aref =  $dbh->selectall_arrayref(
      'SELECT sr.name, sr.length FROM seq_region sr 
       INNER JOIN seq_region_attrib sra USING (seq_region_id) 
       INNER JOIN attrib_type at USING (attrib_type_id)
       WHERE at.code = "karyotype_rank"' 
    );
    $self->db_tree->{'MAX_CHR_NAME'  } = undef;
    $self->db_tree->{'MAX_CHR_LENGTH'} = undef;
    my $max_length = 0;
    my $max_name;
    foreach my $row (@$aref) {
      $self->db_tree->{'ALL_CHROMOSOMES'}{$row->[0]} = $row->[1];
      if( $row->[1] > $max_length ) {
        $max_name = $row->[0];
        $max_length = $row->[1];
      }
    }
    $self->db_tree->{'MAX_CHR_NAME'  } = $max_name;
    $self->db_tree->{'MAX_CHR_LENGTH'} = $max_length;

#
# * Ontologies
#
    my $oref =  $dbh->selectall_arrayref(
     'select distinct(db_name) from ontology_xref 
       left join object_xref using(object_xref_id) 
        left join xref using(xref_id) 
         left join external_db using(external_db_id)'
           );
    foreach my $row (@$oref) {
      push @{$self->db_tree->{'SPECIES_ONTOLOGIES'}}, $row->[0] if ($row->[0]);
    }
  }

#---------------
#
# * Assemblies...
# This is a bit ugly, because there's no easy way to sort the assemblies via MySQL

## EG - don't assume highest rank coord system will have rank=1 (rank doesn't have to start at 1)
##      should be able to remove this whole sub for EG26
  $t_aref = $dbh->selectall_arrayref(
    'select version, attrib from coord_system where version is not null order by rank desc' 
  );

  my (%default, %not_default);
  foreach my $row (@$t_aref) {
    my $version = $row->[0];
    my $attrib  = $row->[1];
    if ($attrib =~ /default_version/) {
      $self->db_tree->{'ASSEMBLY_VERSION'} ||= $version; # get highest ranked default_version
      $default{$version}++;
    }
    else {
      $not_default{$version}++;
    }
  }
  my @assemblies = keys %default;
  push @assemblies, sort keys %not_default;
  $self->db_tree->{'CURRENT_ASSEMBLIES'} = join(',', @assemblies);

##
  
#-------------
#
# * Transcript biotypes
# get all possible transcript biotypes
  @{$self->db_details($db_name)->{'tables'}{'transcript'}{'biotypes'}} = map {$_->[0]} @{$dbh->selectall_arrayref(
    'SELECT DISTINCT(biotype) FROM transcript;'
  )};

#----------
  $dbh->disconnect();
}


1;
