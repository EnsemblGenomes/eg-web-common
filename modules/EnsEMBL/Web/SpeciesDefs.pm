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
  
  my $dataset = $self->get_config($species, 'SPECIES_DATASET');

  if ($dataset && $species ne $dataset) { # add collection
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

sub _load_in_taxonomy_division {}

sub _get_cow_defaults {
## EG to overwrite behaviour on ensembl-webcode in which the sections in 
## default ones are deep-copied into species defs regardless of whether 
## there is any update in the species ini file.
## For EG, we want only copy-on-write. The sections specified in default will 
## only be deep-copied into species defs when there is an update for the same 
## section in the species ini file. Otherwise, a use hashref to point to the one 
## in default.
  my $self = shift;

  $cow_from_defaults = { 
                        'ENSEMBL_SPECIES_SITE'  => 1,
                        'SPECIES_DISPLAY_NAME'  => 1 
                        };
  $cow_from_defaults->{'ENSEMBL_EXTERNAL_URLS'} = 1 if $SiteDefs::ENSEMBL_SITETYPE =~ /bacteria/i;
  return $cow_from_defaults;
}

sub _merge_db_tree {
  my ($self, $tree, $db_tree, $key) = @_;
  return unless defined $db_tree;
  Hash::Merge::set_behavior('RIGHT_PRECEDENT');
  my $t = merge($tree->{$key}, $db_tree->{$key});
  my $cow_from_defaults = %{$self->_get_cow_defaults};
  foreach my $k ( %cow_from_defaults ) {
      $t->{$k} = $tree->{$key}->{$k} if defined $tree->{$key}->{$k};
  }

  $tree->{$key} = $t;
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

sub production_name_mapping {
  ### As the name said, the function maps the production name with the species URL,
  ### @param production_name - species production name
  ### Return string = the corresponding species url name, which is the name web uses for URL and other code, or production name as fallback
  my ($self, $production_name) = @_;
  my $mapping_name = '';

  ## EG - in EG we still use production name. Don't need to map them into url name.
  foreach ($self->valid_species) {
    if ($self->get_config($_, 'SPECIES_PRODUCTION_NAME') eq lc($production_name)) {
      $mapping_name = $self->get_config($_, 'SPECIES_URL');
      last;
    }
  }

  ## EG - species may be from another divison or from external site (e.g. Ensembl)
  ## There are instances where species url is returned
  ## When it isn't returned then production name can be used instead
  return $mapping_name || $production_name;
}

1;
