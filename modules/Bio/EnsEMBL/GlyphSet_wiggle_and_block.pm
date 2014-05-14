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

package Bio::EnsEMBL::GlyphSet_wiggle_and_block;

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
  
  my $height = $self->errorTrack("No $error in this region", 0, $self->_offset);
  $self->_offset($height + 4);
  
  return 1;
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

# gradient drawing code was adapted from Bio::EnsEMBL::GlyphSet::_alignment::render_normal
sub draw_gradient {
  my ($self, $features, $parameters) = @_; 

  # pre-defined transform functions

  my %transforms = (
    default => sub { return $_[0] },
    log2 => sub {
      my $score = shift;
      return 1 if $score == 0;
      return 0 if $score == 1;
      return ( log(1 / $score) / log(2) ) / 10;
    }
  );

  # params

  my $max_score        = $parameters->{max_score} || 1000;
  my $min_score        = $parameters->{min_score} || 0;
  my @gradient_colours = @{ $parameters->{gradient_colours} || [qw(white red)] };
  my $transform        = $transforms{ $parameters->{transform} || 'default' };
  my $bump             = !$parameters->{no_bump};
  my $key_labels       = $parameters->{key_labels} || [$min_score, $max_score];
  my $decimal_places   = $parameters->{decimal_places} || 2;
  my $caption          = $parameters->{caption} || $self->my_config('name');
  
  # create gradient 

  my $colour_grades       = 20;
  my @gradient            = $self->{config}->colourmap->build_linear_gradient($colour_grades, \@gradient_colours);
  my $transform_min_score = min($transform->($min_score), $transform->($max_score));
  my $transform_max_score = max($transform->($min_score), $transform->($max_score));
  my $score_per_grade     = ($transform_max_score - $transform_min_score) / $colour_grades;
  
  my $grade_from_score = sub {
    my $score = shift;
    my $gradient_score = min( max( $transform->($score), $transform_min_score ), $transform_max_score );
    my $grade = $gradient_score >= $transform_max_score ? $colour_grades - 1 : int(($gradient_score - $transform_min_score) / $score_per_grade);    
    return $grade
  };

  # draw...

  my $show_key          = 1;
  my $h                 = 8;
  my $length            = $self->{'container'}->length;
  my $pix_per_bp        = $self->scalex;
  my %font              = $self->get_font_details('innertext', 1);
  my $depth             = $bump ? 6 : 0;
  my $y_offset          = 0;
  my $features_drawn    = 0;
  my $features_bumped   = 0;

  # caption

  my (undef, undef, $text_width, $text_height) = $self->get_text_width(0, $caption, '', %font); 
   
  $self->push($self->Text({
    text      => $caption,
    width     => $text_width,
    height    => $text_height,
    halign    => 'left',
    valign    => 'bottom',
    colour    => 'black',
    y         => $y_offset,
    x         => 1,
    absolutey => 1,
    absolutex => 1,
    %font,
  })); 

  $y_offset += $text_height + 2;

  # features

  $self->_init_bump(undef, $depth);
 
  foreach my $f (sort {$a->{start} <=> $b->{start}} @$features) {
    my $start      = max($f->{start}, 1);
    my $end        = min($f->{end}, $length);
    my $bump_start = int( $pix_per_bp * $start ) - 1;
    my $bump_end   = int( $pix_per_bp * $end );
    my $row        = 0;
    my $colour     = $gradient[ $grade_from_score->($f->{score}) ];

    if ($bump) { 
      
      $row = $self->bump_row($bump_start, $bump_end);
      
      if ($row > $depth) {
        $features_bumped++;
        next;
      }
    }
        
    my $composite = $self->Composite({
      x      => $start - 1,
      y      => 0,
      width  => 0,
      height => $h,
      href  => '',
      title => sprintf "%.${decimal_places}f", $f->{score},
      #title => $f->{score} . " | " . $transform->($f->{score}) . " | " . $grade_from_score->($f->{score}),
      class => 'group',
    });

    $composite->push($self->Rect({
      x            => $start - 1,
      y            => 0,
      width        => $end - $start + 1,
      height       => $h,
      colour       => $colour,
      label_colour => 'black',
    }));
    
    $composite->y( $y_offset + ($row * ($h + 1)) );
    $self->push($composite);

    $features_drawn = 1;
  }

  $y_offset += $h * ($bump ? $self->_max_bump_row() : 1);

  # gradient key

  if ($show_key) {
    my $x_offset    = -10;
    my $y_offset    = 18;
    my $width       = 95;
    my $blocks      = $colour_grades; 
    my $block_size  = int( $width / $blocks );
    my $grade_label = { map { $grade_from_score->($_) => $_ } @$key_labels };

    foreach my $i (1..$blocks) {
        
      my $x = $x_offset - $width + ($block_size * ($i - 1));

      $self->push($self->Rect({
        height        => $block_size,
        width         => $block_size,
        colour        => $gradient[$i],
        y             => $y_offset,
        x             => $x,
        absolutey     => 1,
        absolutex     => 1,
        absolutewidth => 1,
      }));

      if (defined $grade_label->{$i-1}) {
        
        my $label = $grade_label->{$i-1};
        $label = sprintf '%.2f', $grade_label->{$i-1} if $label > int($label);

        my (undef, undef, $text_width, $text_height) = $self->get_text_width(0, $label || 'X', '', %font);

        $self->push($self->Text({
          text          => $label,
          height        => $text_height,
          width         => $text_width,
          halign        => 'left',
          valign        => 'bottom',
          colour        => 'black',
          y             => $y_offset + ($text_height / 2) + 1,
          x             => $x - ($text_width / 2),
          absolutey     => 1,
          absolutex     => 1,
          absolutewidth => 1,
          %font,
        }));
      }

    }
  }

  # messages 

  $self->errorTrack(sprintf q{No features from '%s' in this region}, $caption) unless $features_drawn || $self->{'no_empty_track_message'} || $self->{'config'}->get_option('opt_empty_tracks') == 0;
  $self->errorTrack(sprintf(q{%s features from '%s' omitted}, $features_bumped, $caption), undef, $y_offset) if $self->get_parameter('opt_show_bumped') && $features_bumped;
}

sub draw_wiggle_plot {
  ### Wiggle plot
  ### Args: array_ref of features in score order, colour, min score for features, max_score for features, display label
  ### Description: draws wiggle plot using the score of the features
  ### Returns 1

  my ($self, $features, $parameters, $colours, $labels) = @_; 
  my $slice         = $self->{'container'};
  my $row_height    = $self->{'height'} || $self->my_config('height') || 60;
  my $max_score     = $parameters->{'max_score'};
  my $min_score     = $parameters->{'min_score'};
  my $axis_style    = $parameters->{'graph_type'} eq 'line' ? 0 : 1;
  my %font          = $self->get_font_details('innertext', 1);
  my $name          = $self->my_config('short_name') || $self->my_config('name');
  my $colour        = $parameters->{'score_colour'}  || $self->my_colour('score') || 'blue';
  my $axis_colour   = $parameters->{'axis_colour'}   || $self->my_colour('axis')  || 'red';
  my $label         = $parameters->{'description'}   || $self->my_colour('score', 'text');
     $label         =~ s/\[\[name\]\]/$name/;
  my $textheight    = [ $self->get_text_width(0, $label, '', %font) ]->[3];  
  my $pix_per_score = $max_score == $min_score ? $self->label->height : $row_height / max($max_score - $min_score, 1);
  my $top_offset    = 0;
  my $initial_offset= $self->_offset;
  my $bottom_offset = $max_score == $min_score ? 0 : (($max_score - ($min_score < 0 ? $min_score : 0)) || 1) * $pix_per_score;
  my $zero_offset   = $max_score * $pix_per_score;
  
  # Draw the labels
  ## Only done if we have multiple data sets
  if ($labels) {
    my $header_label = shift @$labels;
    my $y            = $self->_offset;
    my $y_offset     = 0;
    my %font_details = $self->get_font_details('innertext', 1);
    my @res_analysis = $self->get_text_width(0, 'Legend', '', %font_details);
    my $max          = scalar @$labels - 1;
    my ($legend_alt_text, %seen);
    
    if ($header_label eq 'CTCF') {
      $y     += 15; 
      $colour = shift @$colours;
    } else {
      $self->push($self->Text({
        text      => $header_label,
        height    => $res_analysis[3],
        width     => $res_analysis[2],
        halign    => 'left',
        valign    => 'bottom',
        colour    => 'black',
        y         => $y,
        x         => -118,
        absolutey => 1,
        absolutex => 1,
        %font_details,
      }));
    }
    
    for (my $i = 0; $i <= $max; $i++) {
      my $name   = $labels->[$i];
      my $colour = $colours->[$i];
      
      if (!exists $seen{$name}) {  
        $legend_alt_text .= "$name:$colour,";
        $seen{$name}      = 1;
      }
    }
    
    $legend_alt_text =~ s/,$//;
    $y              += 13;
    
    # add colour key legend
    $self->push($self->Rect({
      width         => $res_analysis[2] + 15,
      absolutewidth => $res_analysis[2] + 15,
      height        => $res_analysis[3] + 2,
      y             => $y,
      x             => -109,
      absolutey     => 1,
      absolutex     => 1,
      title         => "$header_label; [$legend_alt_text ]",
      class         => 'coloured',
      bordercolour  => '#336699',
      colour        => 'white',
    }), $self->Text({
      text      => 'Legend',
      height    => $res_analysis[3],
      halign    => 'left',
      valign    => 'bottom',
      colour    => '#336699',
      y         => $y,
      x         => -108,
      absolutey => 1,
      absolutex => 1,
      %font_details,
    }), $self->Triangle({
      width     => 6,
      height    => 5,
      direction => 'down',
      mid_point => [ -113 + $res_analysis[2] + 10, $y + 10 ],
      colour    => '#336699',
      absolutex => 1,
      absolutey => 1,
    }));
    
    $y_offset   += 12;
    $top_offset += 15;
    
    $self->_offset($y_offset);
  }

## EG - move caption to top
  # Add line of text
  $self->push($self->Text({
    text      => $label,
    width     => [ $self->get_text_width(0, $label, '', %font) ]->[2],
    halign    => 'left',
    colour    => 'black',
    y         => 0,
    height    => $textheight,
    x         => 1,
    absolutey => 1,
    absolutex => 1,
    %font,
  })); 

  if (!$labels) { # only change offset if not already done for gutter label
    $top_offset += $textheight;
    $self->_offset($textheight);
  }
##

  # Draw max and min score
  if ($parameters->{'axis_label'} ne 'off') {
    my $height        = [ $self->get_text_width(0, 1, '', %font) ]->[3];
    my $label_height  = 0;
    $label_height = $self->label->height if($self->label);
    $bottom_offset = max($bottom_offset, $top_offset + $label_height + (2 * $height));
    $pix_per_score = $bottom_offset / (($max_score - ($min_score < 0 ? $min_score : 0)) || 1);
    $zero_offset   = $max_score * $pix_per_score;
    
    foreach ([ $max_score, $top_offset ], [ $min_score, $top_offset + $bottom_offset ]) {
      my $text  = sprintf '%.2f', $_->[0];
      my $width = [ $self->get_text_width(0, $text, '', %font) ]->[2];
      
      $self->push($self->Text({
        text          => $text,
        height        => $height,
        width         => $width,
        textwidth     => $width,
        halign        => 'right',
        colour        => $axis_colour,
        y             => $_->[1] + $initial_offset - $height / 2,
        x             => -10 - $width,
        absolutey     => 1,
        absolutex     => 1,
        absolutewidth => 1,
        %font,
      }), $self->Rect({
        height        => 0,
        width         => 5,
        colour        => $axis_colour,
        y             => $_->[1] + $initial_offset,
        x             => -8,
        absolutey     => 1,
        absolutex     => 1,
        absolutewidth => 1,
      }));
    }
    
    $self->{'label_y_offset'} = ($zero_offset - $height)/2;
  }
  
  # Draw the axis
  if (!$parameters->{'no_axis'}) {
    $self->push($self->Line({ # horizontal line
      x         => 0,
      y         => $top_offset + $zero_offset + $initial_offset,
      width     => $slice->length,
      height    => 0,
      absolutey => 1,
      colour    => $axis_colour,
      dotted    => $axis_style,
    }), $self->Line({ # vertical line
      x         => 0,
      y         => $top_offset + $initial_offset,
      width     => 0,
      height    => $row_height,
      absolutey => 1,
      absolutex => 1,
      colour    => $axis_colour,
      dotted    => $axis_style,
    }));
  }
  
  # Draw wiggly plot
  ## Check to see if we have multiple data sets to draw on one axis 
  if (ref $features->[0] eq 'ARRAY') {
    foreach my $feature_set (@$features) {
      $colour = shift @$colours;
      
      if ($parameters->{'graph_type'} eq 'line') {
        $self->draw_wiggle_points_as_line($feature_set, $slice, $parameters, $initial_offset + $top_offset, $pix_per_score, $colour, $zero_offset);
      } else {
        $self->draw_wiggle_points($feature_set, $slice, $parameters, $top_offset, $pix_per_score, $colour, $zero_offset);
      }
    }
  } else {
    $self->draw_wiggle_points($features, $slice, $parameters, $top_offset, $pix_per_score, $colour, $zero_offset);  
  }
    
  return 1;
}

1;
