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

  if ($dataset && lc($prodname) ne lc($dataset)) { # add collection
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
## To overwrite behaviour on ensembl-webcode, in which the sections in 
## DEFAULTS.ini are deep-copied into species defs regardless of whether 
## there is any difference in the species ini file.
## For EG, we want only copy-on-write. The sections specified in default will 
## only be deep-copied into species defs when there is a difference in the same 
## section in the species ini file. Otherwise, use a hashref to point to the one 
## in DEFAULTS.
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
  my %cow_from_defaults = %{$self->_get_cow_defaults};
  foreach my $k ( %cow_from_defaults ) {
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
