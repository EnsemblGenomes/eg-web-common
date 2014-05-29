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

# $Id: Slice.pm,v 1.1 2011-09-20 10:34:04 it2 Exp $

package EnsEMBL::Web::Object::Slice;

sub getFakeMungedVariationFeatures {
  ### Arg1        : Subslices
  ### Arg2        : Optional: gene
  ### Example     : Called from {{EnsEMBL::Web::Object::Transcript.pm}} for TSV
  ### Gets SNPs on slice for display + counts
  ### Returns scalar - number of SNPs on slice post context filtering, prior to other filters
  ### arrayref of munged 'fake snps' = [ fake_s, fake_e, SNP ]
  ### scalar - number of SNPs filtered out by the context filter

  my ($self, $subslices, $gene, $no_munge) = @_;
  my $all_snps = $self->Obj->get_all_VariationFeatures;
  push @$all_snps, @{$self->Obj->get_all_somatic_VariationFeatures};
  my @on_slice_snps = 
    map  { $_->[1] ? [ $_->[0]->start + $_->[1], $_->[0]->end + $_->[1], $_->[0] ] : () } # [ fake_s, fake_e, SNP ] Filter out any SNPs not on munged slice
    map  {[ $_, $self->munge_gaps($subslices, $_->start, $_->end, $no_munge) ]}                      # [ SNP, offset ]         Create a munged version of the SNPS
    grep { $_->map_weight < 4 }                                                           # [ SNP ]                 Filter out all the multiply hitting SNPs
    @$all_snps;

  my $count_snps            = scalar @on_slice_snps;
  my $filtered_context_snps = scalar @$all_snps - $count_snps;
  
  return (0, [], $filtered_context_snps) unless $count_snps;
  return ($count_snps, $self->filter_munged_snps(\@on_slice_snps, $gene), $filtered_context_snps);
}

sub munge_gaps {
  ### Needed for  : TranscriptSNPView, GeneSNPView
  ### Arg1        : Subslices
  ### Arg2        : bp position 1: start
  ### Arg3        : bp position 2: end
  ### Example     : Called from within
  ### Description : Calculates new positions based on subslice
  
  my ($self, $subslices, $bp, $bp2, $no_munge) = @_;

  foreach (@$subslices) {
    return $_->[2] if $no_munge;
    return defined $bp2 && ($bp2 < $_->[0] || $bp2 > $_->[1]) ? undef : $_->[2] if $bp >= $_->[0] && $bp <= $_->[1];
  }
  
  return undef;
}

# Sequence Align View ---------------------------------------------------

sub get_individuals {
  ### SequenceAlignView
  ### Arg (optional) : type string
  ###  - "default"   : returns samples checked by default
  ###  - "reseq"     : returns all resequencing sames
  ###  - "reference" : returns the reference (golden path name)
  ###  - "display"   : returns all samples (for dropdown list) with default ones first
  ### Description    : returns selected samples (by default)
  ### Returns list

  my $self    = shift;
  my $options = shift;
  my $individual_adaptor;
  
  eval {
   $individual_adaptor = $self->variation_adaptor->get_IndividualAdaptor;
  };
  
  if ($@) {
    warn "Error getting individual adaptor off variation adaptor " . $self->variation_adaptor;
    return ();
  }
  
  if ($options eq 'default') {
    return sort  @{$individual_adaptor->get_default_strains};
  } elsif ($options eq 'reseq') {
## EG - fetch_all_strains_with_coverage was dropped for 75, but will be back for 76!
#    return @{$individual_adaptor->fetch_all_strains_with_coverage};
    return @{$individual_adaptor->fetch_all_strains};
##
  } elsif ($options eq 'reference') {
    return $individual_adaptor->get_reference_strain_name || $self->species;
  }

  my %default_pops;
  map { $default_pops{$_} = 1 } @{$individual_adaptor->get_default_strains};
  my %db_pops;
  
  foreach (sort  @{$individual_adaptor->get_display_strains}) {
    next if $default_pops{$_};
    $db_pops{$_} = 1;
  }

  return (sort keys %default_pops), (sort keys %db_pops) if $options eq 'display'; # return list of pops with default first
  return ();
}

1;
