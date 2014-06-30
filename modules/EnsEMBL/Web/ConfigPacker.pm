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

use LWP::UserAgent;
use JSON;
use Data::Dumper;

sub munge_config_tree {
    my $self = shift;

  # munge the results obtained from the database queries of the website and the meta tables
    $self->_munge_meta;
    $self->_munge_variation;
    $self->_munge_website;

# get data about file formats from corresponding Perl modules
    $self->_munge_file_formats;


### EG
    $self->_configure_external_resources;
###
# parse the BLAST configuration
    $self->_configure_blast;
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
		  foreach $src (@{$sources->{'sources'} || []}) {
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

sub _configure_blast {
  my $self = shift;
  my $tree = $self->tree;
  my $species = $self->species;
  $species =~ s/ /_/g;
  my $method = $self->full_tree->{'MULTI'}{'ENSEMBL_BLAST_METHODS'};
  foreach my $blast_type (keys %$method) { ## BLASTN, BLASTP, BLAT, etc
    next unless ref($method->{$blast_type}) eq 'ARRAY';
    my @method_info = @{$method->{$blast_type}};
    my $search_type = uc($method_info[0]); ## BLAST or BLAT at the moment
    my $sources = $self->full_tree->{'MULTI'}{$search_type.'_DATASOURCES'};
    $tree->{$blast_type.'_DATASOURCES'}{'DATASOURCE_TYPE'} = $method_info[1]; ## dna or peptide
    my $db_type = $method_info[2]; ## dna or peptide
    foreach my $source_type (keys %$sources) { ## CDNA_ALL, PEP_ALL, etc
      next if $source_type eq 'DEFAULT';
      next if ($db_type eq 'dna' && $source_type =~ /^PEP/);
      next if ($db_type eq 'peptide' && $source_type !~ /^PEP/);
      if ($source_type eq 'CDNA_ABINITIO') { ## Does this species have prediction transcripts?
        next unless 1;
      }
      elsif ($source_type eq 'RNA_NC') { ## Does this species have RNA data?
        next unless 1;
      }
      elsif ($source_type eq 'PEP_KNOWN') { ## Does this species have species-specific protein data?
        next unless 1;
      }
      my $assembly = $tree->{$species}{'ASSEMBLY_NAME'};
      (my $type = lc($source_type)) =~ s/_/\./ ;
      if ($type =~ /latestgp/) {
        if ($search_type ne 'BLAT') {
          $type =~ s/latestgp(.*)/dna$1\.toplevel/;
          $type =~ s/.masked/_rm/;
          my $repeat_date = $self->db_tree->{'REPEAT_MASK_DATE'} || $self->db_tree->{'DB_RELEASE_VERSION'};
#          my $file = sprintf( '%s.%s.%s.%s', $species, $assembly, $repeat_date, $type ).".fa";
          my $file = sprintf( '%s.%s.%s', $species, $assembly, $type ).".fa";
#          print "AUTOGENERATING $source_type......$file\n";
          $tree->{$blast_type.'_DATASOURCES'}{$source_type} = $file;
        }
      }
      else {
        $type = "ncrna" if $type eq 'rna.nc';
        my $version = $self->db_tree->{'DB_RELEASE_VERSION'} || $SiteDefs::ENSEMBL_VERSION;
#        my $file = sprintf( '%s.%s.%s.%s', $species, $assembly, $version, $type ).".fa";
        my $file = sprintf( '%s.%s.%s', $species, $assembly,  $type ).".fa";
#        print "AUTOGENERATING $source_type......$file\n";
        $tree->{$blast_type.'_DATASOURCES'}{$source_type} = $file;
      }
    }
#    warn "TREE $blast_type = ".Dumper($tree->{$blast_type.'_DATASOURCES'});
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


1;
