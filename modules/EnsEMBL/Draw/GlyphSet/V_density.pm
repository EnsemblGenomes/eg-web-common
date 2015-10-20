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

package EnsEMBL::Draw::GlyphSet::V_density;
use strict;
use List::Util qw( max );

sub build_tracks {
  ## Does data munging common to vertical density tracks
  ## and draws optional max/min lines, as they are needed only once per glyphset
  my ($self, $data) = @_;
  my $chr = $self->{'chr'} || $self->{'container'}->{'chr'};
  my $image_config  = $self->{'config'};
  my $track_config  = $self->{'my_config'};
  
  $data ||= $self->{'data'}{$chr};
  
  ## Translate legacy styles into internal ones
  my $display       = $self->{'display'};
  if ($display) {
    $display =~ s/^density//;
  }
  my $histogram;
  if ($display eq '_bar') {
    $display = '_histogram';
    $histogram = 'fill';
  }
  elsif ($display eq '_outline' || $display eq 'histogram') {
    $display = '_histogram';
  }

  ## Build array of track settings
  my @settings;
	my $chr_min_data ;
  my $chr_max_data  = 0;
	my $slice			    = $self->{'container'}->{'sa'}->fetch_by_region(undef, $chr);
  my $width         = $image_config->get_parameter( 'width') || 80;
  my $max_value     = $image_config->get_parameter( 'max_value' ) || 1;
  my $max_mean      = $image_config->get_parameter( 'max_mean' ) || 1;
  my $bins          = $image_config->get_parameter('bins') || 150;
  my $max_len       = $image_config->container_width();
  my $bin_size      = int($max_len/$bins);
  my $v_offset      = $max_len - ($slice->length() || 1);

  my @sorted = sort {$a->{'sort'} <=> $b->{'sort'}} values %$data;

  foreach my $info (@sorted) {
    my $T = {};
    my $scores = $info->{'scores'};
    next unless $scores && ref($scores) eq 'ARRAY' && scalar(@$scores);
    
    $T->{'style'}     = $info->{'display'} || $display;
    $T->{'histogram'} = $info->{'histogram'} || $histogram;
    $T->{'width'}     = $width;
    $T->{'colour'}    = $info->{'colour'};
    $T->{'max_mean'}  = $max_mean;
    $T->{'max_len'}   = $max_len;
    $T->{'bin_size'}  = $bin_size;
    $T->{'v_offset'}  = $v_offset;

    my $current_max = max @$scores;

    if (uc($chr) eq 'MT'){
      $T->{'max_value'} = undef;
    }
    else {
      $T->{'max_value'} = $info->{'max_value'} || $max_value;
    }

    my $scaled_scores = [];
    my $mins          = [];
    my $maxs          = [];
    my $local_max     = 1;
    foreach(@$scores) { 
      my $mean = $_;
      if (ref($_) eq 'HASH') {
        $mean = $_->{'mean'};
        push $mins, $_->{'min'};
        push $maxs, $_->{'max'};
      } 
      ## Use real values for max/min labels
		  $chr_min_data = $mean if ($mean < $chr_min_data || $chr_min_data eq undef); 
		  $chr_max_data = $mean if $mean > $chr_max_data;
      ## Scale data for actual display
      my $max;

      if ($T->{'max_value'}) {
        $max = $T->{'max_value'};  
        $max = $current_max if ($current_max > $max);
      } else {
        $max = ($current_max > $chr_max_data) ? $current_max : $chr_max_data;
      }
      $local_max = $max;
      push @$scaled_scores, $mean/$max * $width;
	  }

    $T->{'scores'} = $scaled_scores;
    $T->{'mins'}   = $mins;
    $T->{'maxs'}   = $maxs;
    $T->{'max_value'} ||= $local_max;
    push @settings, $T;
  }

  ## Add max/min lines if required
  if ($display eq '_line' && $track_config->get('maxmin') && scalar @settings) {
    $self->label2('Min:'.$chr_min_data.' Max:'.$chr_max_data); 
    $self->push( $self->Space( {
      'x' => 1, 'width' => 3, 'height' => $width, 'y' => 0, 'absolutey'=>1 
    } ));
    # max line (max)
    $self->push( $self->Line({
      'x'      => $v_offset ,
      'y'      => $width,
     'width'  => $max_len - $v_offset,
     'height' => 0,
     'colour' => 'lavender',
     'absolutey' => 1,
    }) );
    # base line (0)
    $self->push( $self->Line({
      'x'      => $v_offset ,
      'y'      => 0 ,
      'width'  => $max_len - $v_offset,
      'height' => 0,
      'colour' => 'lavender',
      'absolutey' => 1,
    }) );
    if ($image_config->get_parameter('all_chromosomes') eq 'yes') {
      # global max line (global max)
      $self->push( $self->Line({
        'x'      => $v_offset,
        'y'      => $width,
        'width'  => $max_len - $v_offset,
        'height' => 0,
        'colour' => 'lightblue',
        'absolutey' => 1,
      }) );
    }
	}

  ## Now add the data tracks
  foreach (@settings) {
    my $style = $_->{'style'};
    $self->$style($_);
  } 
}

1;
