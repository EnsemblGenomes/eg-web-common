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

package EnsEMBL::Draw::GlyphSet_wiggle_and_block;

use strict;

use List::Util qw(min max);

sub _render {
  ## Show both map and features
  
  my $self = shift;
  
  return $self->render_text(@_) if $self->{'text_export'};
  
  ## Check to see if we draw anything because of size!
## EG - allow over whole chromosome
  my $max_length  = $self->my_config('threshold')   || 1_000_000;
##

  my $wiggle_name = $self->my_config('wiggle_name') || $self->my_config('label');

  if ($self->{'container'}->length > $max_length * 1010) {
    my $height = $self->errorTrack("$wiggle_name only displayed for less than $max_length Kb");
    $self->_offset($height + 4);
    
    return 1;
  }
  
  ## Now we try and draw the features
  my $error = $self->draw_features(@_);
  
  return unless $error && $self->{'config'}->get_option('opt_empty_tracks') == 1;
  
  my $here = $self->my_config('strand') eq 'b' ? 'on this strand' : 'in this region';

  my $height = $self->errorTrack("No $error $here", 0, $self->_offset);
  $self->_offset($height + 4);
  
  return 1;
}

1;
