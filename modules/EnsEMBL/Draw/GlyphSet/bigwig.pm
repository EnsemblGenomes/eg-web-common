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

use base qw(EnsEMBL::Draw::GlyphSet::_alignment  EnsEMBL::Draw::GlyphSet_wiggle_and_block);

sub wiggle_subtitle {
  my $self = shift;
  return $self->my_config('longLabel') || $self->my_config('name') || $self->my_config('caption');
}

# get the alignment features
sub wiggle_features {
  my ($self, $bins, $multi_key) = @_;
  my $hub = $self->{'config'}->hub;
  my $has_chrs = scalar(@{$hub->species_defs->ENSEMBL_CHROMOSOMES});
  
  my $wiggle_features = $multi_key ? $self->{'_cache'}{'wiggle_features'}{$multi_key} 
                                   : $self->{'_cache'}{'wiggle_features'}; 

  if (!$wiggle_features) {
    my $slice     = $self->{'container'};
    my $adaptor   = $self->bigwig_adaptor;
    return [] unless $adaptor;
## EG    
    my $summary   = $self->fetch_summary_for_slice($slice, $bins, $has_chrs);
##
    my $bin_width = $slice->length / $bins;
    my $flip      = $slice->strand == -1 ? $slice->length + 1 : undef;
    $wiggle_features = [];
    
    for (my $i = 0; $i < $bins; $i++) {
      next unless defined $summary->[$i];
      push @$wiggle_features, {
        start => $flip ? $flip - (($i + 1) * $bin_width) : ($i * $bin_width + 1),
        end   => $flip ? $flip - ($i * $bin_width + 1)   : (($i + 1) * $bin_width),
        score => $summary->[$i],
      };
    }
  
    if ($multi_key) {
      $self->{'_cache'}{'wiggle_features'}{$multi_key} = $wiggle_features;
    }
    else {
      $self->{'_cache'}{'wiggle_features'} = $wiggle_features;
    }
  }
  
  return $wiggle_features;
}

## get the alignment features
sub wiggle_aggregate {
  my ($self) = @_;
  my $hub = $self->{'config'}->hub;
  my $has_chrs = scalar(@{$hub->species_defs->ENSEMBL_CHROMOSOMES});

  if (!$self->{'_cache'}{'wiggle_aggregate'}) {
    my $slice     = $self->{'container'};
    my $bins      = min($self->{'config'}->image_width, $slice->length);
    my $adaptor   = $self->bigwig_adaptor;
    return {} unless $adaptor;
## EG
#    my $values   = $adaptor->fetch_summary_array($slice->seq_region_name, $slice->start, $slice->end, $bins, $has_chrs);
    my $values  = $self->fetch_summary_for_slice($slice, $bins, $has_chrs);
##
    my $bin_width = $slice->length / $bins;
    my $flip      = $slice->strand == -1 ? $slice->length + 1 : undef;

    $self->{'_cache'}{'wiggle_aggregate'} = {
      unit => $bin_width,
      length => $slice->length,
      strand => $slice->strand,
      max => max(@$values),
      min => min(@$values),
      values => $values,
    };
  }

  return $self->{'_cache'}{'wiggle_aggregate'};
}

sub fetch_summary_for_slice {
  my $self   = shift;
  my $slice  = shift;
  my $values = $self->bigwig_adaptor->fetch_summary_array($slice->seq_region_name, $slice->start, $slice->end, @_);
  
  unless (@$values) {
    foreach my $synonym (@{ $slice->get_all_synonyms }) {
      $values = $self->bigwig_adaptor->fetch_summary_array($synonym->name, $slice->start, $slice->end, @_);
      last if @$values;
    }
  }
  
  return $values;
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

sub min_max_score {
  my ($self, $features) = @_;

  my $viewLimits = $self->my_config('viewLimits');
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

  return $min_score, $max_score;
}

1;
