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

package EnsEMBL::Web::Object::Location;

use strict;
use warnings;
no warnings 'uninitialized';

use previous qw(counts availability);

sub availability {
  my $self = shift;
  $self->PREV::availability(@_);
  $self->{_availability}->{"has_intraspecies_alignments"} = $self->counts->{intraspecies_alignments};
  return $self->{_availability};
}

sub counts {
  my $self = shift;
  $self->PREV::counts(@_);
  my $alignments = $self->count_alignments;
  $self->{_counts}->{"alignments"} = $alignments->{pairwise};
  $self->{_counts}->{"intraspecies_alignments"} = $alignments->{patch};
  return $self->{_counts};
}

sub count_alignments {
  my $self          = shift;
  my $cdb           = shift || 'DATABASE_COMPARA';
  my $c             = $self->SUPER::count_alignments($cdb);

## EG
  unless ($self->{_patch_alignment_count}) {
    my $hub           = $self->hub;
    my $seq_region    = $self->slice->seq_region_name;

    if ($hub->species_defs->POLYPLOIDY) {
      my $gc = $hub->database('core')->get_adaptor('GenomeContainer');
      my @components = @{ $gc->get_genome_components };
      $c->{'patch'} = @components - 1;

    } else {
      $c->{'patch'} = scalar @{ $hub->intra_species_alignments($cdb, $self->species, $seq_region) };
      $c->{'patch'} ++ if $c->{'patch'}; # because we want to include the reference region in the count
    }
    $self->{_patch_alignment_count} = $c;
  }
##

  return $self->{_patch_alignment_count};
}

sub chr_short_name {
  my $self = shift;
  
  my $slice   = shift || $self->slice;
  my $species = shift || $self->species;
  
  my $cs_name = $slice->coord_system_name();
  my $sr_name = $slice->seq_region_name();
  
  my $short_names = { 
    chromosome => 'Chr.', 
    supercontig => q{S'ctg}, 
    plasmid => 'Pla.'
  };
  
  my $slice_name;
  #If they're the same ignoring casing then set to the short name or leave as the sr name 
  if(lc($sr_name) eq lc($cs_name) ) {
    $slice_name = $short_names->{lc($cs_name)} || $sr_name;
  }
  #If the seq region name is not already 'Plasmid F' then do some more re-jigging
  elsif($sr_name !~ /^$cs_name/i) {
    $cs_name = $short_names->{lc $cs_name} || ucfirst $cs_name;
    $slice_name = "$cs_name $sr_name";
  }
  
  my $abbreviated_name;
  my @split_species = split(/_/, $species);
  if(scalar(@split_species) == 2) {
    $abbreviated_name = join(q{}, substr($split_species[0], 0, 1), substr($split_species[-1], 0, 3));
  }
  else {
    $abbreviated_name = $species;
  }
  
  return "$abbreviated_name $slice_name";
}

1;
