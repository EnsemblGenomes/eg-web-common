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

1;
