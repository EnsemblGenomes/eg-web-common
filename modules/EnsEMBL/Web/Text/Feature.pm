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

package EnsEMBL::Web::Text::Feature;

use strict;
use warnings;
no warnings "uninitialized";

sub map {
  my( $self, $slice ) = @_;
  my $chr = $self->seqname(); 
  $chr=~s/^chr//;

  # $chr is imported chr name, $slice->seq_region_name defaults to '01'
  my $synonym_obj = $slice->get_all_synonyms();
  my @syns;
  
  push @syns, grep { $_ eq $chr}
    map { $_->name } @$synonym_obj;
  
  # if imported chr name not equal default name or synonym name
  # no data available

  return () if ($chr ne $slice->seq_region_name && !@syns);

  my $start = $self->rawstart();
  my $slice_end = $slice->end();
  return () unless $start <= $slice_end;
  my $end   = $self->rawend();
  my $slice_start = $slice->start();
  return () unless $slice_start <= $end;
  $self->slide( 1 - $slice_start );
  
  if ($slice->strand == -1) {
    my $flip = $slice->length + 1;
    ($self->{'start'}, $self->{'end'}) = ($flip - $self->{'end'}, $flip - $self->{'start'});
  }
  
  return $self;
}

1;
