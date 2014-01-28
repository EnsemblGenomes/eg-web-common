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

package Bio::EnsEMBL::GlyphSet::gsv_domain;

sub _init {
  my ($self) = @_;
  my $type = $self->type;
  return unless defined $type; 
  
  return unless $self->strand() == -1;  
  my $key = lc($type).'_hits';
  $key =~s/domain_//;

  my $Config        = $self->{'config'};
  my $trans_ref = $Config->{'transcript'}; 
  my $offset = $self->{'container'}->start - 1;
    
  my $y             = 0;
  my $h             = 8;   #Single transcript mode - set height to 30 - width to 8!
    
  my %highlights;
  @highlights{$self->highlights} = ();    #build hashkeys of highlight list

  my( $fontname, $fontsize ) = $self->get_font_details( 'outertext' );
  my @res = $self->get_text_width( 0, 'X', '', 'font' => $fontname, 'ptsize' => $fontsize );
  my $th = $res[3];
  my $pix_per_bp = $self->{'config'}->transform()->{'scalex'};  
  
  #my $bitmap_length = $Config->image_width(); 
  my $bitmap_length = int($Config->container_width() * $pix_per_bp); 

  my $length  = $Config->container_width(); 
  my $transcript_drawn = 0;
    
  my $voffset = 0;
  my $strand = $trans_ref->{'exons'}[0][2]->strand;  
  my $gene = $trans_ref->{'gene'};
  my $transcript = $trans_ref->{'transcript'}; 

  #Variation image fix BOF
  my $flag_feat = 0;
  foreach my $domain_ref0 ( @{$trans_ref->{$key}||[]} ) {
       my($domain,@pairs) = @$domain_ref0;
       my $min_S;
       my $max_E;
       my $cnt = 0;
       while( my($S,$E) = splice( @pairs,0,2 ) ) {
         $min_S = $S  if $S < $min_S || !$cnt;
         $max_E = $E  if $E > $max_E || !$cnt;
         $cnt++;
       }
       $flag_feat = 1 if (($min_S >= 0) && ($min_S <= $length)) || (($max_E >= 0) && ($max_E <= $length)) || (($min_S <= 0) && ($max_E >= $length));
  }

  # In Gene/Variation image page it doesn't show the track unless there is a part of a feature to be displayed                                        
  return unless $flag_feat || ($Config->{'var_image'} != 1);
  #Variation image fix EOF

  my @bitmap = undef; 
  my $flag_y;

  foreach my $domain_ref ( @{$trans_ref->{$key}||[]} ) { 
    my($domain,@pairs) = @$domain_ref;  

    my $Composite3 = $self->Composite({
      'y'         => 0,
      'height'    => $h,
      'href'  => $self->_url({ 'type' => 'Transcript', 'action' => 'ProteinSummary', 'pf_id' => $domain->dbID }),
    });

    my $flag_feat2 = 0;   
    while( my($S,$E) = splice( @pairs,0,2 ) ) {  

      my $x = $S;
      my $width =  (($E >= $length) && ($S < $length)) ? $length-$S : $E-$S;
      my $height = $h;
      my $y = 0;
      if ( ($S < 0) && ($E > 0) ) {
        $x = 0;
        $width = $E > $length ? $length : $E;
      } elsif (($S < 0) && ($E <= 0))  {
        $x = 0;
        $width = 0;
        $height = 0;      
        $y = $h/2;
      }
      $flag_feat2++ if ($width > 0);
      $flag_y = (($x <= $length) && $width )  ? 1 : 0;

      $Composite3->push( $self->Rect({
      'x' => $x,                       #$S,
      'y' => $y,
      'width' => $width,               #$E-$S,
      'height' => $height,
      'colour' => 'purple4',
      'absolutey' => 1,
      }));
    }

    my $x = $Composite3->{'x'};
    my $width = (($x >= 0) && ($x + $Composite3->{'width'})) > $length ? $length-$x : $Composite3->{'width'};
    if ( ($Composite3->{'x'} < 0) && (($Composite3->{'x'} + $Composite3->{'width'}) > 0) ) {
      $x = 0;
      $width = ($Composite3->{'x'} + $Composite3->{'width'}) > $length ? $length : ($Composite3->{'x'} + $Composite3->{'width'});
    } elsif ( ($Composite3->{'x'} < 0) && (($Composite3->{'x'} + $Composite3->{'width'}) < 0) ) {
      $x = 0;
      $width = 0;
    }
    $flag_feat2++ if ($width > 0);

    #Draw the lines 
    $Composite3->push( $self->Rect({
      'x' => $x,                         #$Composite3->{'x'},
      'width' => $width,                 #$Composite3->{'width'},
      'y' => $h/2,
      'height' => 0,
      'colour' => 'purple4',
      'absolutey' => 1
    }));   
    
    if ($flag_feat2) {   
        my $text_label = $domain->hseqname;  
        my @res = $self->get_text_width( 0, $text_label, '', 'font' => $fontname, 'ptsize' => $fontsize );
        $Composite3->push( $self->Text({
        'x'         => $Composite3->{'x'},
        'y'         => $h,
        'height'    => $th,
        'width'     => $res[2]/$pix_per_bp,
        'font'      => $fontname,
        'ptsize'    => $fontsize,
        'halign'    => 'left', 
        'colour'    => 'purple4',
        'text'      => $text_label,
        'absolutey' => 1,
        }));
        $text_label = $domain->idesc; 
        @res = $self->get_text_width( 0, $text_label, '', 'font' => $fontname, 'ptsize' => $fontsize );
        $Composite3->push( $self->Text({
        'x'         => $Composite3->{'x'},
        'y'         => $h+2 + $th,
        'height'    => $th,
        'width'     => $res[2]/$pix_per_bp,
        'font'      => $fontname,
        'ptsize'    => $fontsize,
        'halign'    => 'left', 
        'colour'    => 'purple4',
        'text'      => $text_label,
        'absolutey' => 1,
        }));
    } #if flag_feat2

    my $bump_start = int($Composite3->{'x'} * $pix_per_bp);
       $bump_start = 0 if ($bump_start < 0);
       $bump_start = $bitmap_length if ($bump_start > $bitmap_length);
    my $bump_end = $bump_start + int($Composite3->width()*$pix_per_bp) +1;
       $bump_end = 0 if ($bump_end < 0);
       $bump_end = $bitmap_length if ($bump_end > $bitmap_length);

    if ($flag_y > 0) {	
      my $row = & Sanger::Graphics::Bump::bump_row( $bump_start, $bump_end, $bitmap_length, \@bitmap);    
      $Composite3->y( $voffset + $Composite3->{'y'} + $row * ($h+$th*2+5) );
    }

    $self->push( $Composite3 );
  } #foreach

}

1;
