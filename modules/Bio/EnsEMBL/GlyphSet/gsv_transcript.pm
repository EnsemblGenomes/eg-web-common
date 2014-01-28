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

package Bio::EnsEMBL::GlyphSet::gsv_transcript;

sub _init {
  my ($self) = @_; 
  my $type = $self->check(); 

  return unless defined $type;
  return unless $self->strand() == -1;
  my $offset = $self->{'container'}->start - 1;
  my $Config        = $self->{'config'}; 

  my @transcripts   = $Config->{'transcripts'}; 
  my $y             = 0;
  my $h             = 8;   #Single transcript mode - set height to 30 - width to 8!
    
  my %highlights; 
  @highlights{$self->highlights} = ();    # build hashkeys of highlight list

  my $pix_per_bp    = $Config->transform->{'scalex'};
  my $bitmap_length = $Config->image_width();   #int($Config->container_width() * $pix_per_bp);

  my $length  = $Config->container_width();
  my $transcript_drawn = 0;

  my $voffset      = 0;
  my $trans_ref    = $Config->{'transcript'};
  my $strand       = $trans_ref->{'exons'}[0][2]->strand;
  my $gene         = $trans_ref->{'gene'};
  my $transcript   = $trans_ref->{'transcript'};
  my @exons        = sort {$a->[0] <=> $b->[0]} @{$trans_ref->{'exons'}};
  # If stranded diagram skip if on wrong strand
  # For exon_structure diagram only given transcript
  my $Composite    = $self->Composite({'y'=>0,'height'=>$h});

  my $colour           = $self->my_colour($self->colour_key($gene, $transcript));
  my $coding_start = $trans_ref->{'coding_start'};
  my $coding_end   = $trans_ref->{'coding_end'  };

  my( $fontname, $fontsize ) = $self->get_font_details( 'caption' );
  my @res = $self->get_text_width( 0, 'X', '', 'font'=>$fontname, 'ptsize' => $fontsize );
  my $th = $res[3];

  ## First of all draw the lines behind the exons..... 
  my $Y = $Config->{'_add_labels'} ? $th : 0;  

  unless ($Config->{'var_image'} == 1) {
    foreach my $subslice (@{$Config->{'subslices'}}) {
      $self->push( $self->Rect({
        'x' => $subslice->[0]+$subslice->[2]-1, 'y' => $Y+$h/2, 'h'=>1, 'width'=>$subslice->[1]-$subslice->[0], 'colour'=>$colour, 'absolutey'=>1
      }));
    }
  }  

  ## Now draw the exons themselves....
  my $drawn_exon = 0;
  foreach my $exon (@exons) { 
    next unless defined $exon;  #Skip this exon if it is not defined (can happen w/ genscans) 
      # We are finished if this exon starts outside the slice
    my($box_start, $box_end);
      # only draw this exon if is inside the slice

    if ($exon->[0] < 0 && $transcript->slice->is_circular) {  # Features overlapping chromosome origin
        $exon->[0] += $transcript->slice->seq_region_length;
        $exon->[1] += $transcript->slice->seq_region_length;
        $coding_start += $transcript->slice->seq_region_length;
        $coding_end += $transcript->slice->seq_region_length;
    }

    $box_start = $exon->[0];
    $box_start = 1 if $box_start < 1 ;
    $box_end   = $exon->[1];
    $box_end = $length if$box_end > $length;
    # Calculate and draw the coding region of the exon
    if ($coding_start && $coding_end) {
      my $filled_start = $box_start < $coding_start ? $coding_start : $box_start;
      my $filled_end   = $box_end > $coding_end  ? $coding_end   : $box_end;
       # only draw the coding region if there is such a region
       if( $filled_start <= $filled_end ) {

	   my $x     = $filled_start -1;
	   my $width = $filled_end - $filled_start + 1;

	   if (($x >= 0) && ($width >= 0)) {
	       $width = ($x + $width) > $length ? $length-$x : $width;
	   } elsif ( ($x <= 0) && (($x + $width) > 0) ) {
	       $width = ($x + $width) > $length ? $length : ($x + $width);
	       $x = 0;
	   }

	   if ($width > 0 ) {
             #Draw a filled rectangle in the coding region of the exon
             $self->push( $self->Rect({
             'x' =>         $x,     #$filled_start -1,
             'y'         => $Y,
             'width'     => $width, #$filled_end - $filled_start + 1,
             'height'    => $h,
             'colour'    => $colour,
             'absolutey' => 1,
             'href'     => $self->href( $transcript, $exon->[2] ),
             }));
	   } #if
      }
    }
     if($box_start < $coding_start || $box_end > $coding_end ) {
      # The start of the transcript is before the start of the coding
      # region OR the end of the transcript is after the end of the
      # coding regions.  Non coding portions of exons, are drawn as
      # non-filled rectangles

      my $x     = $box_start - 1;
      my $width = $box_end-$box_start  + 1;

      if (($x >= 0) && ($width >= 0)) {
        $width = ($x + $width) > $length ? $length-$x : $width;
      } elsif ( ($x <= 0) && (($x + $width) > 0) ) {
	$width = ($x + $width) > $length ? $length : ($x + $width);
	$x = 0;
      }

      if ($width > 0 ) {
        #Draw a non-filled rectangle around the entire exon
        my $G = $self->Rect({
        'x'         => $x,      #$box_start -1 ,
        'y'         => $Y,
        'width'     => $width,  #$box_end-$box_start +1,
        'height'    => $h,
        'bordercolour' => $colour,
        'absolutey' => 1,
        'title'     => $exon->[2]->stable_id,
        'href'     => $self->href( $transcript, $exon->[2] ),
        });
        $self->push( $G );
      } #if
     } 
  } #we are finished if there is no other exon defined


  if ($Config->{'var_image'} == 1) {      ## Drawing the lines behind the exons for Gene/Variation image  

    my @l_exons = sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @exons;
    my $start_ex = $l_exons[0];
    my $end_ex   = $l_exons[$#l_exons];
    my $S = $start_ex->[0];
    my $E = $end_ex->[1];

    # In Gene/Variation image page it doesn't show the track unless there is a part of the trancript to be displayed
    return if ($E<1 || $S>$length) && ($Config->{'var_image'} == 1);
    $S = 1 if $S < 1;
    $E = $length if $E > $length;
    my $tglyph = $self->Rect({
      'x' => $S-1,
      'y' => $Y+$h/2, 
      'h'=>1,
      'width'  => $E-$S+1,
      'colour' => $colour,
      'absolutey'=>1
    });
    $self->push($tglyph);
  }

  if( $Config->{'_add_labels'} ) {   
    my $H = 0;
    my  $T = length( $transcript->stable_id );
    my $name =  ' '.$transcript->external_name;
    $T = length( $name ) if length( $name ) > $T ;
    foreach my $text_label ( $transcript->stable_id, $name ) {
      next unless $text_label;
      next if $text_label eq ' ';

      my $tglyph = $self->Text({
       # 'x'         => - $width_of_label,
        'x'         => -100,
        'y'         => $H,
        'height'    => $th,
        'width'     => 0,
        'font'      => $fontname,
        'ptsize'    => $fontsize,
        'halign'    => 'left',
        'colour'    => $colour,
        'text'      => $text_label,
        'absolutey' => 1,
        'absolutex' => 1,
      });
      $H += $th + 1;
      $self->push($tglyph);
    }
  }
}

sub render_normal {
    my $self = shift;
    my $type = $self->type;

    return unless defined $type;
    return unless $self->strand == -1;

    my $offset           = $self->{'container'}->start - 1;
    my $config           = $self->{'config'};
    my @transcripts      = $config->{'transcripts'};
    my $y                = 0;
    my $h                = 8; # Single transcript mode - set height to 30 - width to 8
    my $pix_per_bp       = $config->transform->{'scalex'};
    my $bitmap_length    = $config->image_width;
    my $length           = $config->container_width;
    my $transcript_drawn = 0;
    my $voffset          = 0;
    my $trans_ref        = $config->{'transcript'};
    my $strand           = $trans_ref->{'exons'}[0][2]->strand;
    my $gene             = $trans_ref->{'gene'};
    my $transcript       = $trans_ref->{'transcript'};
    my @exons            = sort { $a->[0] <=> $b->[0] } @{$trans_ref->{'exons'}};
    my $colour           = $self->my_colour($self->colour_key($gene, $transcript));
    my $coding_start     = $trans_ref->{'coding_start'};
    my $coding_end       = $trans_ref->{'coding_end'};
    my $var_image        = $config->{'var_image'};

    my ($fontname, $fontsize) = $self->get_font_details('caption');
    my @res = $self->get_text_width(0, 'X', '', font => $fontname, ptsize => $fontsize);
    my $th  = $res[3];
    $y   = $config->{'_add_labels'} ? $th : 0;

  ## First of all draw the lines behind the exons.....
    unless ($var_image) { 
      foreach my $subslice (@{$config->{'subslices'}}) {
	$self->push($self->Rect({
          x         => $subslice->[0] + $subslice->[2] - 1,
          y         => $y + $h / 2,
          h         => 1,
          width     => $subslice->[1] - $subslice->[0],
          colour    => $colour,
          absolutey => 1
        }));
      }
    }

    ## Now draw the exons themselves....
    my $drawn_exon = 0;
    foreach my $exon (@exons) {
	next unless defined $exon; # Skip this exon if it is not defined (can happen w/ genscans)

    # We are finished if this exon starts outside the slice
	my ($box_start, $box_end);

    # only draw this exon if is inside the slice
	if ($exon->[0] < 0 && $transcript->slice->is_circular) { # Features overlapping chromosome origin
	    my $transcript_length = $transcript->slice->seq_region_length;

	    $exon->[0]    += $transcript_length;
	    $exon->[1]    += $transcript_length;
	    $coding_start += $transcript_length;
	    $coding_end   += $transcript_length;
	}

	$box_start = $exon->[0];
	$box_start = 1 if $box_start < 1;
	$box_end   = $exon->[1];
	$box_end   = $length if $box_end > $length;

    # Calculate and draw the coding region of the exon
	if ($coding_start && $coding_end) {
	    my $filled_start = $box_start < $coding_start ? $coding_start : $box_start;
	    my $filled_end   = $box_end   > $coding_end   ? $coding_end   : $box_end;


            # only draw the coding region if there is such a region
	    if ($filled_start <= $filled_end) {
            
              # EG:
              my $x     = $filled_start -1;
	      my $width = $filled_end - $filled_start + 1;

              if (($x >= 0) && ($width >= 0)) {
	        $width = ($x + $width) > $length ? $length-$x : $width;
	      } elsif ( ($x <= 0) && (($x + $width) > 0) ) {
	        $width = ($x + $width) > $length ? $length : ($x + $width);
	        $x = 0;
	      }

              if ($width > 0 ) {
                # Draw a filled rectangle in the coding region of the exon
		$self->push($self->Rect({
                  x         => $x,     #$filled_start -1,
                  y         => $y,
                  width     => $width, #$filled_end - $filled_start + 1,
                  height    => $h,
                  colour    => $colour,
                  absolutey => 1,
                  href      => $self->href($transcript, $exon->[2]),
                }));
	      } #if
              # EG
	    }
	}

	if ($box_start < $coding_start || $box_end > $coding_end ) {
          # The start of the transcript is before the start of the coding
          # region OR the end of the transcript is after the end of the
          # coding regions.  Non coding portions of exons, are drawn as
          # non-filled rectangles
          # Draw a non-filled rectangle around the entire exon

          # EG
          my $x     = $box_start - 1;
          my $width = $box_end-$box_start  + 1;

          if (($x >= 0) && ($width >= 0)) {
            $width = ($x + $width) > $length ? $length-$x : $width;
          } elsif ( ($x <= 0) && (($x + $width) > 0) ) {
            $width = ($x + $width) > $length ? $length : ($x + $width);
	    $x = 0;
          }

          if ($width > 0 ) {
	    $self->push($self->Rect({
              x            => $x,     #$box_start - 1 ,
              y            => $y,
              width        => $width, #$box_end - $box_start + 1,
              height       => $h,
              bordercolour => $colour,
              absolutey    => 1,
              title        => $exon->[2]->stable_id,
               href         => $self->href($transcript, $exon->[2]),
            }));
          } #if
          #EG
      }
    } # we are finished if there is no other exon defined

    # EG:
    if ($var_image) {      ## Drawing the lines behind the exons for Gene/Variation image
	my @l_exons = sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @exons;
	my $start_ex = $l_exons[0];
	my $end_ex   = $l_exons[$#l_exons];
	my $S = $start_ex->[0];
	my $E = $end_ex->[1];

        # In Gene/Variation image page it doesn't show the track unless there is a part of the trancript to be displayed
	return if ($E<1 || $S>$length) && ($var_image == 1);
	$S = 1 if $S < 1;
	$E = $length if $E > $length;
	my $tglyph = $self->Rect({
         'x' => $S-1,
         'y' => $y+$h/2,
         'h'=>1,
         'width'  => $E-$S+1,
         'colour' => $colour,
         'absolutey'=>1
        });
	$self->push($tglyph);
    }
    # EG

    if ($config->{'_add_labels'}) {
	$h = 0;
	my $l    = length $transcript->stable_id;
	my $name =  ' ' . $transcript->external_name;
	$l    = length $name if length $name > $l;

	foreach my $text_label ($transcript->stable_id, $name) {
	    next unless $text_label;
	    next if $text_label eq ' ';
	    $self->push($self->Text({
        x         => -100,
        y         => $h,
        height    => $th,
        width     => 0,
        font      => $fontname,
        ptsize    => $fontsize,
        halign    => 'left',
        colour    => $colour,
        text      => $text_label,
        absolutey => 1,
        absolutex => 1,
    }));

	    $h += $th + 1;
	}
    }
}



1;
