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

#use strict;
use warnings;

use previous qw(retrieve);

sub _get_WUBLAST_source_file { shift->_get_NCBIBLAST_source_file(@_) }

sub _get_NCBIBLAST_source_file {
  my ($self, $species, $source_type) = @_;

  my $assembly = $self->get_config($species, 'ASSEMBLY_NAME');

  (my $type = lc $source_type) =~ s/_/\./;

  my $unit = $self->GENOMIC_UNIT;
  my $path = $self->EBI_BLAST_DB_PREFIX || "ensemblgenomes/$unit";
  
  my $dataset = $self->get_config($species, 'SPECIES_DATASET');

  if ($species ne $dataset) { # add collection prefix
    $path   .= '/' . ucfirst $dataset;
    $species = lcfirst $species if $unit eq 'bacteria';
  }

  $path .= '/' . lc $species; # add species folder

  return sprintf '%s/%s.%s.%s', $path, $species, $assembly, $type unless $type =~ /latestgp/;

  $type =~ s/latestgp(.*)/dna$1\.toplevel/;
  $type =~ s/.masked/_rm/;
  $type =~ s/.soft/_sm/;

  return sprintf '%s/%s.%s.%s', $path, $species, $assembly, $type;
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
  $CONF->{'_storage'} = {};

  $self->_info_log('Parser', 'Starting to parse tree');

  my $tree          = {};
  my $db_tree       = {};
  my $config_packer = EnsEMBL::Web::ConfigPacker->new($tree, $db_tree);
  
  $self->_info_line('Parser', 'Child objects attached');

  # Parse the web tree to create the static content site map
  $tree->{'STATIC_INFO'}  = $self->_load_in_webtree;
  ## Parse species directories for static content
  $tree->{'SPECIES_INFO'} = $self->_load_in_species_pages;
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
  foreach my $species (@$SiteDefs::ENSEMBL_DATASETS, 'MULTI') {
    $config_packer->species($species);
    
    $self->process_ini_files($species, $config_packer, $defaults);
    $self->_merge_db_tree($tree, $db_tree, $species);
  }
  
  $self->_info_log('Parser', 'Post processing ini files');
  
  # Loop over each tree and make further manipulations
  foreach my $species (@$SiteDefs::ENSEMBL_DATASETS, 'MULTI') {
    $config_packer->species($species);
    $config_packer->munge('config_tree');
    $self->_info_line('munging', "$species config");
  }

## EG MULTI
  foreach my $db (@$SiteDefs::ENSEMBL_DATASETS ) {
    my @species = map {ucfirst} @{$tree->{$db}->{DB_SPECIES}};
    my $species_lookup = { map {$_ => 1} @species };

    foreach my $sp (@species) {
        $self->_merge_species_tree( $tree->{$sp}, $tree->{$db}, $species_lookup);
    }
  }
##  

  $CONF->{'_storage'} = $tree; # Store the tree
}

## EG MULTI
sub _merge_species_tree {
  my ($self, $a, $b, $species_lookup) = @_;

  foreach my $key (keys %$b) {
## EG - don't bloat the configs with references to all the other speices in this dataset    
      next if $species_lookup->{$key}; 
##      
      $a->{$key} = $b->{$key} unless exists $a->{$key};
  }
}
##


## EG always return true so that we never force a config repack
##    this allows us to run util scripts from a different server to where the configs were packed
sub retrieve {
  my $self = shift;
  $self->PREV::retrieve;
  return 1; 
}
##


1;
