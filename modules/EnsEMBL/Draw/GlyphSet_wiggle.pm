=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Draw::GlyphSet_wiggle;

use strict;
use List::Util qw(max);

sub _draw_wiggle_points_as_bar_or_points {
  my ($self,$c,$features,$parameters) = @_;

  my $hrefs     = $parameters->{'hrefs'};
  my $use_points    = $parameters->{'graph_type'} eq 'points';
  my $max_score = $parameters->{'max_score'};
## EG - ENSEMBL-3226 support infinity       
  my $min_score     = $parameters->{'min_score'};
  my $line_score    = $c->{'line_score'};
  my $pix_per_score = $c->{'pix_per_score'};
##
  my $slice_length = $self->{'container'}->length;


  foreach my $f (@$features) {
    my $href = $self->_feature_href($f,$hrefs||{});
    my $colour = $self->_special_colour($f,$parameters) || $c->{'colour'};
    my ($start,$end,$score) = $self->_feature_values($f,$slice_length);

## EG - ENSEMBL-3226 support infinity         
    my $height;
    if ($score =~ /INF/) {
      $colour = 'black';
      $height = ($max_score - $line_score) * $pix_per_score if $score eq 'INF';
      $height = ($min_score - $line_score) * $pix_per_score if $score eq '-INF';
    } else{ 
      $height = ($score - $line_score) * $pix_per_score;
    }

    my $title = $self->score_title($score);
##

    $self->push($self->Rect({
      y         => $c->{'line_px'} - max($height, 0),
      height    => $use_points ? 0 : abs $height,
      x         => $start - 1,
      width     => $end - $start + 1,
      absolutey => 1,
      colour    => $colour,
      alpha     => $parameters->{'use_alpha'} ? 0.5 : 0,
      title     => $parameters->{'no_titles'} ? undef : $title,
      href      => $href,
    }));
  }
}

sub score_title {
  my ($self, $score) = @_;
  return 'Infinite value'           if $score eq 'INF';
  return 'Negavtive infinite value' if $score eq '-INF';
  return sprintf('%.2f', $score);
}

1; 