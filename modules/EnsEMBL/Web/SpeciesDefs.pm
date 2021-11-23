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

package EnsEMBL::Web::SpeciesDefs;

use strict;
use warnings;

use previous qw(retrieve);

sub _get_WUBLAST_source_file { shift->_get_NCBIBLAST_source_file(@_) }

sub _get_NCBIBLAST_source_file {
  my ($self, $species, $source_type) = @_;

  my $assembly = $self->get_config($species, 'ASSEMBLY_NAME');

  (my $type = lc $source_type) =~ s/_/\./;

  my $unit = $self->GENOMIC_UNIT;
  my $path = ($self->EBI_BLAST_DB_PREFIX || "ensemblgenomes") . "/$unit";
  
  my $dataset   = $self->get_config($species, 'SPECIES_DATASET');
  my $prodname  = $self->get_config($species, 'SPECIES_PRODUCTION_NAME');

  if ($dataset && $prodname ne $dataset) { # add collection
    $path .= '/' . lc($dataset) . '_collection';
  }

  $path .= '/' . $prodname; # add species folder

  return sprintf '%s/%s.%s.%s', $path, ucfirst($prodname), $assembly, $type unless $type =~ /latestgp/;

  $type =~ s/latestgp(.*)/dna$1\.toplevel/;
  $type =~ s/.masked/_rm/;
  $type =~ s/.soft/_sm/;

  return sprintf '%s/%s.%s.%s', $path, ucfirst($prodname), $assembly, $type;
}

## EG ENSEMBL-2967 - abbreviate long species names
sub abbreviated_species_label {
  my ($self, $species, $threshold) = @_;
  $threshold ||= 15;

  my $label = $self->species_label($species, 'no_formatting');

  if (length $label > $threshold) {
    my @words = split /\s/, $label;
    if (@words == 2) {
      $label = substr($words[0], 0, 1) . '. ' . $words[1];
    } elsif (@words > 2) {
      $label = join '. ', substr(shift @words, 0, 1), substr(shift @words, 0, 1), join(' ', @words);
    }
  }

  return $label;
}
##

#------------------------------------------------------------------------------
# MULTI SPECIES
#------------------------------------------------------------------------------

sub _parse {
  ### Does the actual parsing of .ini files
  ### (1) Open up the DEFAULTS.ini file(s)
  ### Foreach species open up all {species}.ini file(s)
  ###  merge in content of defaults
  ###  load data from db.packed file
  ###  make other manipulations as required
  ### Repeat for MULTI.ini
  ### Returns: boolean

  my $self = shift;

  {  
    no strict "vars";
    $CONF->{'_storage'} = {};
  }

  $self->_info_log('Parser', 'Starting to parse tree');

  my $tree          = {};
  my $db_tree       = {};
  my $config_packer = EnsEMBL::Web::ConfigPacker->new($tree, $db_tree);
  
  $self->_info_line('Parser', 'Child objects attached');

  # Parse the web tree to create the static content site map
  $tree->{'STATIC_INFO'}  = $self->_load_in_webtree;
  $self->_info_line('Filesystem', 'Trawled web tree');
  
  $self->_info_log('Parser', 'Parsing ini files and munging dbs');
  
  # Grab default settings first and store in defaults
  my $defaults = $self->_read_in_ini_file('DEFAULTS', {});
  $self->_info_line('Parsing', 'DEFAULTS ini file');

 
  # Loop for each species exported from SiteDefs
  # grab the contents of the ini file AND
  # IF  the DB packed files exist expand them
  # o/w attach the species databases
  # load the data and store the packed files
  foreach my $species (@$SiteDefs::PRODUCTION_NAMES, 'MULTI') {
    $config_packer->species($species);
    
    $self->process_ini_files($species, $config_packer, $defaults);
    $self->_merge_db_tree($tree, $db_tree, $species);
  }

  $self->_info_log('Parser', 'Post processing ini files');
 
  # Prepare to process strain information
  my $species_to_strains = {};
  my $species_to_assembly = {};
 
  # Loop over each tree and make further manipulations
  foreach my $species (@$SiteDefs::PRODUCTION_NAMES, 'MULTI') {
    $config_packer->species($species);
    $config_packer->munge('config_tree');
    $self->_info_line('munging', "$species config");

    ## Need to gather strain info for all species
    $config_packer->tree->{'IS_REFERENCE'} = 1;
    $config_packer->tree->{'STRAIN_GROUP'} = undef if $SiteDefs::NO_STRAIN_GROUPS;
    my $strain_group = $config_packer->tree->{'STRAIN_GROUP'};
    if ($strain_group) {
      $config_packer->tree->{'IS_REFERENCE'} = 0 if ($strain_group ne $species);
      if (!$config_packer->tree->{'IS_REFERENCE'}) {
        push @{$species_to_strains->{$strain_group}}, $config_packer->tree->{'SPECIES_URL'}; ## Key on actual URL, not production name
      }
    }
  } 

 ## Compile strain info into a single structure
  while (my($k, $v) = each (%$species_to_strains)) {
    $tree->{$k}{'ALL_STRAINS'} = $v;
  } 

  ## Final munging
  my $datasets = [];

## EG - loop through ALL keys; we can't use @$SiteDefs::PRODUCTION_NAMES as per Ensembl 
##      because that list doesn't include genomes in the collection dbs         
  foreach my $key (sort keys %$tree) {
    next unless (defined $tree->{$key}{'SPECIES_URL'}); # skip if not a species key
    my $prodname = $key;

    my $url = $tree->{$prodname}{'SPECIES_URL'};

    ## Add in aliases to production names
    my $aliases  = $tree->{'MULTI'}{'ENSEMBL_SPECIES_URL_MAP'};
    $aliases->{$prodname} = $url;

    ## Rename the tree keys for easy data access via URLs
    ## (and backwards compatibility!)
    $tree->{$url} = $tree->{$prodname};
    push @$datasets, $url;
    delete $tree->{$prodname} if $prodname ne $url;
  }

  # For EG we need to merge collection info into the species hash
  foreach my $prodname (@$SiteDefs::PRODUCTION_NAMES) {
    next unless $tree->{$prodname};
    my @db_species = @{$tree->{$prodname}->{DB_SPECIES}};
    my $species_lookup = { map {$_ => 1} @db_species };
    foreach my $sp (@db_species) {
      $self->_merge_species_tree( $tree->{$sp}, $tree->{$prodname}, $species_lookup);
    } 
  }
  
  ## Assign a display name and image to this species
  foreach my $key (sort keys %$tree) {
    next unless (defined $tree->{$key}{'SPECIES_URL'}); # skip if not a species key

    ## Check for a) genome-specific image, b) species-specific image
    my $no_image  = 1;
    ## Need to use full path, as image files are usually in another plugin
    my $image_dir = sprintf '%s/eg-web-%s/htdocs/i/species', $SiteDefs::ENSEMBL_SERVERROOT, $SiteDefs::DIVISION;
    my $image_path = sprintf '%s/%s.png', $image_dir, $key;
    ## In theory this could be a trinomial, but we use whatever is set in species.species_name
    my $binomial = $tree->{$key}{SPECIES_BINOMIAL};
    if ($binomial) {
      $binomial =~ s/ /_/g;
    }
    else {
      ## Make a guess based on URL. Note that some fungi have weird URLs bc 
      ## their taxonomy is uncertain, so this regex doesn't try to include them
      ## (none of them have images in any case)
      $key =~ /^([A-Za-z]+_[a-z]+)/;
      $binomial = $1;
    }
    my $species_path = $binomial ? sprintf '%s/%s.png', $image_dir, $binomial : '';
    if (-e $image_path) {
      $tree->{$key}{'SPECIES_IMAGE'} = $key;
      $no_image = 0;
    }
    elsif ($species_path && -e $species_path) {
      $tree->{$key}{'SPECIES_IMAGE'} = $binomial;
      $no_image = 0;
    }
    else {
      $tree->{$key}{'SPECIES_IMAGE'} = 'default';
      $no_image = 0;
    }
  }

  $tree->{'MULTI'}{'ENSEMBL_DATASETS'} = $datasets;

  ## File format info 
  my $format_info = $self->_get_file_format_info($tree);;
  $tree->{'MULTI'}{'UPLOAD_FILE_FORMATS'} = $format_info->{'upload'};
  $tree->{'MULTI'}{'REMOTE_FILE_FORMATS'} = $format_info->{'remote'};
  $tree->{'MULTI'}{'DATA_FORMAT_INFO'} = $format_info->{'formats'};

  ## Parse species directories for static content
  $tree->{'SPECIES_INFO'} = $self->_load_in_species_pages;
  {
    no strict "vars";
    $CONF->{'_storage'} = $tree; # Store the tree
  }
  $self->_info_line('Filesystem', 'Trawled species static content');

}

sub _load_in_taxonomy_division {}

sub _get_deepcopy_defaults {
## To overwrite behaviour on ensembl-webcode, in which the sections in 
## DEFAULTS.ini are deep-copied into species defs regardless of whether 
## there is any difference in the species ini file.
## For EG, we want only copy-on-write. The sections specified in default will 
## only be deep-copied into species defs when there is a difference in the same 
## section in the species ini file. Otherwise, use a hashref to point to the one 
## in DEFAULTS.
  my $self = shift;

  my $deepcopy_defaults = { 
                            'ENSEMBL_SPECIES_SITE'  => 1,
                            'SPECIES_DISPLAY_NAME'  => 1
                          };
  $deepcopy_defaults->{'ENSEMBL_EXTERNAL_URLS'} = 1 if $SiteDefs::ENSEMBL_SITETYPE =~ /bacteria/i;
  return $deepcopy_defaults;
}

sub _merge_db_tree {
  my ($self, $tree, $db_tree, $key) = @_;
  return unless defined $db_tree;
  Hash::Merge::set_behavior('RIGHT_PRECEDENT');
  my $t = merge($tree->{$key}, $db_tree->{$key});
  my %deepcopy_from_defaults = %{$self->_get_deepcopy_defaults};
  foreach my $k ( keys %deepcopy_from_defaults ) {
      $t->{$k} = $tree->{$key}->{$k} if defined $tree->{$key}->{$k};
  }

  $tree->{$key} = $t;
}


## EG always return true so that we never force a config repack
##    this allows us to run util scripts from a different server to where the configs were packed
sub retrieve {
  my $self = shift;
  $self->PREV::retrieve;
  return 1; 
}
##

1;
