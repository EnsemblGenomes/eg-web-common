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

package EnsEMBL::Web::Component::Gene::S4DASUniprot;

use strict;
use EBeyeSearch::EBeyeWSWrapper;
use base qw(EnsEMBL::Web::Component::Gene::S4DAS);

# given segment hashref, return filtered segments arrayref
sub _filter_segments {
  my ($self, $segments) = @_;
  return [] unless %$segments;
  
  my $species_defs = $self->hub->species_defs;
  
  # We may have many segments each with a different uniprot accession number
  # We want only one segment, so...
  #  1. If there is already just one cross-reference, we use it.
  #  2. If there are multiple references,
  #    a. We take the SwissProt one (EB-eye: status=reviewed)
  #    b. If there are all unreviewed, we take the longest sequence (EB-eye: sequence_length) 
  
  # only one?
  return [values %$segments] if (values %$segments == 1);
  
  # get uniprot meta data
  my $ws = EBeyeSearch::EBeyeWSWrapper->new({endpoint => $species_defs->S4DAS_EBEYE_ENDPOINT});
  my @meta;
  foreach my $accesion (keys %$segments) {
    my $hits = $ws->getResultsAsHashArray('uniprot', $accesion, ['status', 'sequence_length'], 0, 10); 
    my $first_hit = shift @$hits;
    push @meta, {accession => $accesion, status => $first_hit->{status}, sequence_length => $first_hit->{sequence_length}} 
  }
  
  # if any are reviewed, keep only these
  if (my @reviewed = grep {$_->{status} eq 'reviewed'} @meta) {
    @meta = @reviewed;
  } 
  
  # find the longest sequence
  my $longest = (sort {$a->{sequence_length} <=> $b->{sequence_length}} @meta)[-1];
  
  return [$segments->{$longest->{accession}} || values %$segments] ;
}

# given features arrayref, return filtered arrayref
sub _filter_features {
  my ($self, $features) = @_; 
  return [] unless @{$features};
  
  # There could be multiple groups of features (eg features might be grouped by PDBE id)
  # We want only the first group
  # Features are grouped based on a prefix in the id, eg '3omw' is the prefix for id '3omw-description' 

  (my $prefix = $features->[0]->display_id) =~ s/(-[^-]*)$//; 
     
  return [grep {$_->display_id =~ /^$prefix/} @{$features}];
}


1;
