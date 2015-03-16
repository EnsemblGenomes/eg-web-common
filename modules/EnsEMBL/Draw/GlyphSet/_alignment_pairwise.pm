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

package EnsEMBL::Draw::GlyphSet::_alignment_pairwise;

### Draws compara pairwise alignments - see EnsEMBL::Web::ImageConfig
### and E::W::ImageConfig::MultiBottom for usage

use strict;


# Draws either a CIGAR or non-cigar line of boxes, as appropriate.
sub draw_boxes {
  my ($self,$net_composite,$ga_s,$y_pos,$zm) = @_;
 
  my $feature_key    = lc $self->my_config('type');
  my $pix_per_bp     = $self->scalex;
## EG ENSEMBL-3424 not possible to show joins between cigar & non-cigar boxes - so only draw non-cigars 
  my $draw_cigar     = 0;#$pix_per_bp > 0.2 || $debug_force_cigar;
##   
  my $container      = $self->{'container'};
  my $length         = $container->length;

  my $params = {
    feature_colour => $self->my_colour($feature_key),
    delete_colour  => 'black',
    y              => $y_pos,
    h              => $self->get_parameter('opt_halfheight') ? 4 : 8,
    link           => $self->get_parameter('compara') ? $self->my_config('join') : 0,
  };
  my (%joins);

  foreach my $gab (@$ga_s) {
    my @tag = (
      #Need to use original_dbID if GenomicAlign has been restricted
      $gab->reference_genomic_align->dbID() || $gab->reference_genomic_align->original_dbID,
      $gab->get_all_non_reference_genomic_aligns->[0]->dbID() || $gab->get_all_non_reference_genomic_aligns->[0]->original_dbID
    );

    @tag = reverse @tag if $self->strand == 1; # Flip on bottom of link
    my $args = {
      drawx => $self->should_draw_cross($gab),
      tag => \@tag,
    };
    if ($draw_cigar) {
      my $composite = $net_composite;
      unless(defined $composite) {
        my ($x,$width,$ori,$r,$r1) = $self->calculate_region($gab);
        $composite = $self->draw_containing_box([$gab],0);
        $self->add_zmenu($zm,$composite,$ori,$r,$r1);
        $self->push($composite);
      }
      $self->draw_cigar($params,$args,$composite,$gab,\%joins);
    } else {
      $self->draw_non_cigar($params,$args,$gab,\%joins,$zm);
    }
  }
  $self->draw_joins(\%joins);
}

1;
