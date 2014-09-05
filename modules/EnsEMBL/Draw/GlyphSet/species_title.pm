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

package EnsEMBL::Draw::GlyphSet::species_title;

### Draws an arrow showing the direction of the strand, labelled with
### the size of the current region (in kb) - by default, one is drawn at the 
### very top of the image and one at the very bottom

use strict;

use base qw(EnsEMBL::Draw::GlyphSet);

sub _init {
  my ($self) = @_;
  return if $self->strand != 1;

  my $species      = $self->my_config('species') || $self->{config}->{species};
  my $display_name = $self->species_defs->species_display_label($species);
  my $pix_per_bp   = $self->scalex; 
  my $gutter_width = 120;
  my $padding      = 4; 

  my ($fontname, $fontsize) = $self->get_font_details('legend');
  my (undef, undef, $w, $h) = $self->get_text_width( 0, $display_name, '', font => $fontname, ptsize => $fontsize );

  $self->push($self->Rect({ 
    x         => -$gutter_width / $pix_per_bp, 
    y         => 0,
    height    => $h + $padding * 2, 
    width     => ($w + $padding * 2) / $pix_per_bp,
    absolutey => 1,
    colour    => 'gainsboro',
  }));

  $self->push($self->Text({
    x         => ($padding - $gutter_width) / $pix_per_bp, 
    y         => $padding / 2,
    height    => $h,
    halign    => 'left',
    font      => $fontname,
    ptsize    => $fontsize,
    colour    => 'black',
    text      => $display_name,
    absolutey => 1,
  }));
}

1;
