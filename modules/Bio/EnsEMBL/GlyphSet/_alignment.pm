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

package Bio::EnsEMBL::GlyphSet::_alignment;

use strict;


use Data::Dumper;

sub render_normal {
  my $self = shift;
  
  return $self->render_text if $self->{'text_export'};
  
  my $tfh    = $self->{'config'}->texthelper()->height($self->{'config'}->species_defs->ENSEMBL_STYLE->{'GRAPHIC_FONT'});
  my $h      = @_ ? shift : ($self->my_config('height') || 8);
  my $dep    = @_ ? shift : ($self->my_config('dep'   ) || 6);
  my $gap    = $h<2 ? 1 : 2;   
## Information about the container...
  my $strand = $self->strand;
  my $strand_flag    = $self->my_config('strand');

  my $length = $self->{'container'}->length();

## EG
  my $start_point = $self->{'container'}->start;
  my $end_point = $self->{'container'}->end;
  my $reg_end = $self->{'container'}->seq_region_length;
  my $addition = 0;
###

## And now about the drawing configuration
  my $pix_per_bp     = $self->scalex;
  my $DRAW_CIGAR     = ( $self->my_config('force_cigar') eq 'yes' )|| ($pix_per_bp > 0.2) ;
  
## Highlights...
  my %highlights = map { $_,1 } $self->highlights;
  my $hi_colour = 'highlight1';

  if( $self->{'extras'} && $self->{'extras'}{'height'} ) {
    $h = $self->{'extras'}{'height'};
  }

## Get array of features and push them into the id hash...
  my %features = $self->features;

  #get details of external_db - currently only retrieved from core since they should be all the same
  my $db = 'DATABASE_CORE';
#  my $db = 'DATABASE_'.uc($self->my_config('db'));
  my $extdbs = $self->species_defs->databases->{$db}{'tables'}{'external_db'}{'entries'};

  my $y_offset = 0;

  my $features_drawn = 0;
  my $features_bumped = 0;
  my $label_h = 0;
  my( $fontname, $fontsize ) ;
  if( $self->{'show_labels'} ) {
    ( $fontname, $fontsize ) = $self->get_font_details( 'outertext' );
    my( $txt, $bit, $w,$th ) = $self->get_text_width( 0, 'X', '', 'ptsize' => $fontsize, 'font' => $fontname );
    $label_h = $th;
  }

  ## Sort (user tracks) by priority 
  my @sorted = $self->sort_features_by_priority(%features);
  unless (@sorted) {
    @sorted = $strand < 0 ? sort keys %features : reverse sort keys %features;
  }

  foreach my $feature_key (@sorted) {
    ## Fix for userdata with per-track config
    my ($config, @features);
    $self->{'track_key'} = $feature_key;
    next unless $features{$feature_key};
    my @T = @{$features{$feature_key}};
    if (ref($T[0]) eq 'ARRAY') {
      @features =  @{$T[0]};
      $config   = $T[1];
      $dep      ||= $T[1]->{'dep'};
    }
    else {
      @features = @T;
    }

    $self->_init_bump( undef, $dep );
    my %id = ();
    foreach my $f (
      map { $_->[2] }
      sort{ $a->[0] <=> $b->[0] }
      map { [$_->start,$_->end, $_ ] }
      @features
    ){
 

     my $hstrand  = $f->can('hstrand')  ? $f->hstrand : 1;
      # e! splits the feature id on dots and uses the first part as a group name - in EG it is not valid assumption - we dont group features this way
      # it should be done at a db level
#      my $fgroup_name = $f->hseqname;
  
      my $fgroup_name = $self->feature_group( $f );
      
      my $s =$f->start;
      my $e =$f->end;

#     warn join ' * ', $f->id, $s, $e, "\n";



      my $db_name = $f->can('external_db_id') ? $extdbs->{$f->external_db_id}{'db_name'} : 'OLIGO';
      next if $strand_flag eq 'b' && $strand != ( ($hstrand||1)*$f->strand || -1 ) || $e < 1 || $s > $length ;
      push @{$id{$fgroup_name}}, [$s,$e,$f,int($s*$pix_per_bp),int($e*$pix_per_bp),$db_name];
    }

    ## Now go through each feature in turn, drawing them
    my ($cgGrades, $score_per_grade, @colour_gradient);
    my @greyscale      = (qw/cccccc a8a8a8 999999 787878 666666 484848 333333 181818 000000/);
    my $y_pos;
    my $colour_key     = $self->colour_key( $feature_key );
    my $feature_colour = $self->my_colour( $colour_key, undef  );
    my $label_colour   = $feature_colour;
    my $join_colour    = $self->my_colour( $colour_key, 'join' );
    my $max_score      = $config->{'max_score'} || 1000;
    my $min_score      = $config->{'min_score'} || 0;
    if ($config && $config->{'useScore'} == 2) {
      $cgGrades = $config->{'cgGrades'} || 20;
      $score_per_grade =  ($max_score - $min_score)/ $cgGrades ;
      my @cgColours = map { $config->{$_} }
                      grep { (($_ =~ /^cgColour/) && $config->{$_}) }
                      sort keys %$config;
      if (my $ccount = scalar(@cgColours)) {
        if ($ccount == 1) {
          unshift @cgColours, 'white';
        }
      }
      else {
        @cgColours = ('yellow', 'green', 'blue');
      }
      my $cm = new Sanger::Graphics::ColourMap;
      @colour_gradient = $cm->build_linear_gradient($cgGrades, \@cgColours);
    }

    my $regexp = $pix_per_bp > 0.1 ? '\dI' : ( $pix_per_bp > 0.01 ? '\d\dI' : '\d\d\dI' );

    next unless keys %id;
    foreach my $i ( sort {
      $id{$a}[0][3] <=> $id{$b}[0][3]  ||
      $id{$b}[-1][4] <=> $id{$a}[-1][4]
    } keys %id){
      my @F          = @{$id{$i}}; # sort { $a->[0] <=> $b->[0] } @{$id{$i}};
      my $START      = $F[0][0] < 1 ? 1 : $F[0][0];
      my $END        = $F[-1][1] > $length ? $length : $F[-1][1];
      my $db_name    = $F[0][5];
      my( $txt, $bit, $w, $th );
      my $bump_start = int($START * $pix_per_bp) - 1;
      my $bump_end   = int($END * $pix_per_bp);

      if ($config) {
        my $f = $F[0][2];
        if ($config->{'useScore'} == 1) {
          my $index = int(($f->score * scalar(@greyscale)) / 1000);
          $feature_colour = $greyscale[$index];
        }
        elsif ($config->{'useScore'} == 2) {
          my $score = $f->score || 0;
          $score = $min_score if ($score < $min_score);
          $score = $max_score if ($score > $max_score);
          my $grade = ($score >= $max_score) ? ($cgGrades - 1) : int(($score - $min_score) / $score_per_grade);
          $feature_colour = $colour_gradient[$grade];
        }
      }
      if( $self->{'show_labels'} ) {
        my $title = $self->feature_label( $F[0][2],$db_name );
        my( $txt, $bit, $tw,$th ) = $self->get_text_width( 0, $title, '', 'ptsize' => $fontsize, 'font' => $fontname );
        my $text_end = $bump_start + $tw + 1;
        $bump_end = $text_end if $text_end > $bump_end;
      }
      my $row        = $self->bump_row( $bump_start, $bump_end );
      if( $row > $dep ) {
        $features_bumped++;
        next;
      }
      $y_pos = $y_offset - $row * int( $h + $gap * $label_h ) * $strand;

## EG
      if(($start_point>$end_point) && ($F[0][0]->slice->end == $end_point)) {
          $addition = $reg_end - $start_point + 1;
      } else {
          $addition = 0;
      }
##


      my $Composite = $self->Composite({
        'href'  => $self->href( $F[0][2] ),
	'x'     =>   $F[0][0]> 1 ? $F[0][0] + $addition - 1 : 0 + $addition, ## EG
        'width' => 0,
        'y'     => 0,
        'title' => $self->feature_title($F[0][2],$db_name),
	      'class' => 'group',
      });
      my $X = -1e8;
      foreach my $f ( @F ){ ## Loop through each feature for this ID!
        my( $s, $e, $feat ) = @$f;
        if ($config->{'itemRgb'} =~ /on/i) {
          $feature_colour = $feat->external_data->{'item_colour'}[0];
        }
        next if int($e * $pix_per_bp) <= int( $X * $pix_per_bp );
        $features_drawn++;
        my $cigar;
        eval { $cigar = $feat->cigar_string; };
        if($DRAW_CIGAR || $cigar =~ /$regexp/ ) {
           my $START = $s < 1 ? 1 : $s;
           my $END   = $e > $length ? $length : $e;
           $X = $END;
           $Composite->push($self->Space({
             'x'          => $START-1,
             'y'          => 0, # $y_pos,
             'width'      => $END-$START+1,
             'height'     => $h,
             'absolutey'  => 1,
          }));

          $self->draw_cigar_feature({
            composite      => $Composite, 
            feature        => $feat, 
            height         => $h, 
            feature_colour => $feature_colour, 
            label_colour   => $label_colour,
            delete_colour  => 'black', 
            scalex         => $pix_per_bp
          });
        } else {
          my $START = $s < 1 ? 1 : $s;
          my $END   = $e > $length ? $length : $e;
          $X = $END;
          $Composite->push($self->Rect({
            'x'          => $START-1,
            'y'          => 0, # $y_pos,
            'width'      => $END-$START+1,
            'height'     => $h,
            'colour'     => $feature_colour,
            'label_colour' => $label_colour,
            'absolutey'  => 1,
          }));
        }
      }

      ## EG circular
      if(($start_point>$end_point) && ($F[0][2]->slice->end == $end_point)) {
	  $addition = $reg_end - $start_point + 1;
      } else {
	  $addition = 0;
      }
      ##

      if( $h > 1 ) {
        $Composite->bordercolour($feature_colour);
      } else {
        $Composite->unshift( $self->Rect({
          'x'         => $Composite->{'x'} + $addition, ## EG
          'y'         => $Composite->{'y'},
	        'width'     => $Composite->{'width'},
	        'height'    => $h,
	        'colour'    => $join_colour,
	        'absolutey' => 1
        }));
      }
      $Composite->y( $Composite->y + $y_pos );
      $self->push( $Composite );
      if( $self->{'show_labels'} ) {

        $self->push( $self->Text({
          'font'      => $fontname,
          'colour'    => $label_colour,
          'height'    => $fontsize,
          'ptsize'    => $fontsize,
          'text'      => $self->feature_label($F[0][2],$db_name),
          'title'     => $self->feature_title($F[0][2],$db_name),
          'halign'    => 'left',
          'valign'    => 'center',
          'x'         => $Composite->{'x'} + $addition, ## EG
          'y'         => $Composite->{'y'} + $h + 2,
          'width'     => $Composite->{'x'} + ($bump_end-$bump_start) / $pix_per_bp,
          'height'    => $label_h,
          'absolutey' => 1
        }));
      }
      if(exists $highlights{$i}) {
        $self->unshift( $self->Rect({
          'x'         => $Composite->{'x'} + $addition - 1/$pix_per_bp, ## EG
          'y'         => $Composite->{'y'} - 1,
          'width'     => $Composite->{'width'} + 2/$pix_per_bp,
          'height'    => $h + 2,
          'colour'    => 'highlight1',
          'absolutey' => 1,
        }));
      }
    }
    $y_offset -= $strand * ( ($self->_max_bump_row ) * ( $h + $gap + $label_h ) + 6 );
  }
  $self->errorTrack("No features from '" . $self->my_config('name') . "' in this region") unless $features_drawn || $self->{'no_empty_track_message'} || $self->{'config'}->get_option('opt_empty_tracks') == 0;

  if( $self->get_parameter( 'opt_show_bumped') && $features_bumped ) {
    my $y_pos = $strand < 0
              ? $y_offset
              : 2 + $self->{'config'}->texthelper()->height($self->{'config'}->species_defs->ENSEMBL_STYLE->{'GRAPHIC_FONT'})
              ;
    $self->errorTrack( sprintf( q(%s features from '%s' omitted), $features_bumped, $self->my_config('name')), undef, $y_offset );
  }
  $self->timer_push( 'Features drawn' );
## No features show "empty track line" if option set....
}

1;
