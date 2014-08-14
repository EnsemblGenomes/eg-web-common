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

package EnsEMBL::Draw::GlyphSet::bigwig;

use strict;

use List::Util qw(min max);
use Bio::EnsEMBL::SimpleFeature;
use Bio::EnsEMBL::ExternalData::BigFile::BigWigAdaptor;

use base qw(EnsEMBL::Draw::GlyphSet::_alignment  EnsEMBL::Draw::GlyphSet_wiggle_and_block);

# get the alignment features
sub wiggle_features {
  my ($self, $bins) = @_;

## EG
  my $slice = $self->{'container'};
  if (!$self->{'_cache'}{'wiggle_features'}) {
    my $summary = $self->bigwig_adaptor->fetch_extended_summary_array($slice->seq_region_name, $slice->start, $slice->end, $bins) || [];

    # check summary by synonym name unless not found by name
    if ( !@$summary ){
      my $synonym_obj = $slice->get_all_synonyms(); # arrayref of Bio::EnsEMBL::SeqRegionSynonym objects
      foreach my $synonym (@$synonym_obj) {
        $summary =  $self->bigwig_adaptor->fetch_extended_summary_array($synonym->name, $slice->start, $slice->end, $bins);
        last if (ref $summary eq 'ARRAY' && @$summary > 0);
      }
    }
##

    my $bin_width = $slice->length / $bins;
    my $flip      = $slice->strand == -1 ? $slice->length + 1 : undef;
    my @features;
    
    for (my $i = 0; $i < $bins; $i++) {
      next unless $summary->[$i]{'validCount'} > 0;
      
      push @features, {
        start => $flip ? $flip - (($i + 1) * $bin_width) : ($i * $bin_width + 1),
        end   => $flip ? $flip - ($i * $bin_width + 1)   : (($i + 1) * $bin_width),
        score => $summary->[$i]{'sumData'} / $summary->[$i]{'validCount'},
      };
    }
    
    $self->{'_cache'}{'wiggle_features'} = \@features;
  }
  
  return $self->{'_cache'}{'wiggle_features'};
}

sub draw_features {
  my ($self, $wiggle) = @_;
  my $slice        = $self->{'container'};
  my $feature_type = $self->my_config('caption');
  my $colour       = $self->my_config('colour');

  # render wiggle if wiggle
  if ($wiggle) {
    my $max_bins   = min($self->{'config'}->image_width, $slice->length);
    my $features   = $self->wiggle_features($max_bins);
    my $viewLimits = $self->my_config('viewLimits');
    my $no_titles  = $self->my_config('no_titles');
    
    my ($min_score, $max_score) = $self->min_max_score($features);
    
    # render wiggle plot        
    $self->draw_wiggle_plot($features, {
      min_score    => $min_score, 
      max_score    => $max_score,
## EG
      description  => $self->my_config('name'),
      #description  => $feature_type,
##         
      score_colour => $colour,         
      no_titles    => defined $no_titles,
    });
    
    $self->draw_space_glyph;
  }

  warn q{bigwig glyphset doesn't draw blocks} if !$wiggle || $wiggle eq 'both';
  
  return 0;
}

sub render_gradient {
  my $self = shift;
  
  my $slice    = $self->{'container'};
  my $max_bins = min($self->{'config'}->image_width, $slice->length);
  my $features = $self->wiggle_features($max_bins);

  my ($min_score, $max_score) = $self->min_max_score($features);

  $self->draw_gradient($features, { 
    min_score        => $min_score,
    max_score        => $max_score,
    gradient_colours => $self->species_defs->GRADIENT_COLOURS || [qw(yellow green blue)],
    no_bump          => 1,
  });
}

sub render_pvalue {
  my $self = shift;
  
  my $slice    = $self->{'container'};
  my $max_bins = min($self->{'config'}->image_width, $slice->length);
  my $features = $self->wiggle_features($max_bins);

  $self->draw_gradient($features, { 
    min_score      => 0,
    max_score      => 1,
    key_labels     => [ 0, 0.05, 1 ],
    transform      => 'log2',
    decimal_places => 5,
  });
}

1;
