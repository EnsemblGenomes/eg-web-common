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

package Bio::EnsEMBL::GlyphSet::bigwig;

use strict;

use List::Util qw(min max);
use Bio::EnsEMBL::SimpleFeature;
use Bio::EnsEMBL::ExternalData::BigFile::BigWigAdaptor;

use base qw(Bio::EnsEMBL::GlyphSet::_alignment  Bio::EnsEMBL::GlyphSet_wiggle_and_block);

# get the alignment features
sub wiggle_features {
  my ($self, $bins) = @_;

## EG
  my $slice = $self->{'container'};
  if (!$self->{'_cache'}{'wiggle_features'}) {
    my $summary = $self->bigwig_adaptor->fetch_extended_summary_array($slice->seq_region_name, $slice->start, $slice->end, $bins);

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
    my $min_score;
    my $max_score;
    
    if ($viewLimits) {
      ($min_score, $max_score) = split ':', $viewLimits;
    } else {
      $min_score = $features->[0]{'score'};
      $max_score = $features->[0]{'score'};
      
      foreach my $feature (@$features) {
        $min_score = min($min_score, $feature->{'score'});
        $max_score = max($max_score, $feature->{'score'});
      }
    }
    
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

## EG gradient

sub render_gradient {
  my $self = shift;
  
  $self->{'renderer_no_join'} = 1;
  $self->{'legend'}{'gradient_legend'} = 1; # instruct to draw legend  
  $self->SUPER::render_normal(8, 0);
  
  # Add text line showing name and score range
  
  my %features = $self->features;
  my $fconf    = $features{url}->[1];
  my $label    = sprintf '%s  %.2f - %.2f', $self->my_config('name'), $fconf->{min_score}, $fconf->{max_score};
  my %font     = $self->get_font_details('innertext', 1);
  
  my (undef, undef, $width, $height) = $self->get_text_width(0,  $label, '', %font); 
  
  $self->push($self->Text({
    text      => $label,
    width     => $width,
    halign    => 'left',
    valign    => 'bottom',
    colour    => $self->my_config('colour'),
    y         => 7,
    height    => $height,
    x         => 1,
    absolutey => 1,
    absolutex => 1,
    %font,
  })); 
}

sub href {
  return ''; # this causes the zmenu content to be supressed (leaving only title)
}

sub feature_title {
  my ($self, $f) = @_;
  return sprintf '%.2f', $f->score; # the score is all that we want to show
}

sub feature_group {
  my ($self, $f) = @_;
  my $name = '';
  if ($f->can('hseqname')) {
    ($name = $f->hseqname) =~ s/(\..*|T7|SP6)$//; # this regexp will remove the differences in names between the ends of BACs/FOSmids.
  }
  return $name;
}

sub features {
  my $self = shift;
  
  if (!$self->{_cache}->{bw_features}) {
  
    my $slice = $self->{'container'};
  
    my $max_bins = $self->{'config'}->image_width();
    if ($max_bins > $slice->length) {
      $max_bins = $slice->length;
    }
  
    my $feats =  $self->wiggle_features($max_bins);
  
    my $min_score = $feats->[0]->{score};
    my $max_score = $feats->[0]->{score};
    
    my @features;
  
    my $fake_anal = Bio::EnsEMBL::Analysis->new(-logic_name => 'fake');
    foreach my $feat (@$feats) {
      $min_score = min($min_score, $feat->{score});
      $max_score = max($max_score, $feat->{score});     
      
      my $f = Bio::EnsEMBL::SimpleFeature->new(-start => $feat->{start}, 
                                               -end => $feat->{end}, 
                                               -slice => $slice, 
                                               -strand => 1, 
                                               -score => $feat->{score}, 
                                               -analysis => $fake_anal);
      push @features, $f;
    }
  
    my $viewLimits = $self->my_config('viewLimits');
    if ($viewLimits) {
      ($min_score, $max_score) = split ":",$viewLimits;
    } 
    
    my $config = {};
    $config->{'implicit_colour'} = 1;
    $config->{'greyscale_max'}   = 100;
    
    # this config is for the gradient renderer
    $config->{'max_score'}       = $max_score;
    $config->{'min_score'}       = $min_score;
    $config->{'useScore'}        = 2;
  
    $self->{_cache}->{bw_features} = {'url' => [ \@features, $config ]};
  }

  return %{ $self->{_cache}->{bw_features} };
}

## EG /gradient

1;
