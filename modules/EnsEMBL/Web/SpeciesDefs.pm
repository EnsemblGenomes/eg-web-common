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

# For EG we generate blast configs on the fly to avoid packing these for 20k+ bacteria

sub get_blast_datasources {
  my ($self, $species) = @_;

  my $blast_types = $self->multi_val('ENSEMBL_BLAST_TYPES');
  my $sources     = $self->get_config($species, 'ENSEMBL_BLAST_DATASOURCES_BY_TYPE') || $self->multi_val('ENSEMBL_BLAST_DATASOURCES_BY_TYPE');
  my $blast_conf  = {};

  while (my ($blast_type, undef) = each %$blast_types) { #BLAT, NCBIBLAST, WUBLAST etc
    next if $blast_type eq 'ORDER';

    my $method = sprintf '_get_%s_source_file', $blast_type;

    $blast_conf->{$blast_type}{$_} = $self->$method($species, $_) for @{$sources->{$blast_type} || []} #LATESTGP, CDNA_ALL, PEP_ALL etc
  }

  return $blast_conf;
}

sub _get_WUBLAST_source_file { shift->_get_NCBIBLAST_source_file(@_) }

sub _get_NCBIBLAST_source_file {
  my ($self, $species, $source_type) = @_;

  my $assembly = $self->get_config($species, 'ASSEMBLY_NAME');

  (my $type = lc $source_type) =~ s/_/\./;

  my $unit = $self->GENOMIC_UNIT;
  
  if ($unit eq 'bacteria') { # add collection prefix
    $species = join '/', ucfirst($self->get_config($species, 'SPECIES_DATASET')), $species;
  }

  return sprintf 'ensemblgenomes/%s/%s.%s.%s', $unit, $species, $assembly, $type unless $type =~ /latestgp/;

  $type =~ s/latestgp(.*)/dna$1\.toplevel/;
  $type =~ s/.masked/_rm/;
  $type =~ s/.soft/_sm/;

  return sprintf 'ensemblgenomes/%s/%s.%s.%s', $unit, $species, $assembly, $type;
}

1;
