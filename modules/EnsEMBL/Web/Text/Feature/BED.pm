=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Text::Feature::BED;

use strict;
use warnings;

sub _raw_score    { 
  my $self = shift;

  my $score = 0;
## EG - ENSEMBL-3226 infinity
  if ( exists($self->{'__raw__'}[4]) && $self->{'__raw__'}[4] =~ /^-*(\d+\.?\d*|inf)$/i) {
    $score = uc($self->{'__raw__'}[4]);
  }
  elsif ($self->{'__raw__'}[3] =~ /^-*(\d+\.?\d*|inf)$/i) { ## Possible bedGraph format
    $score = uc($self->{'__raw__'}[3]);
  } 
##  
  return $score;
}

1;
