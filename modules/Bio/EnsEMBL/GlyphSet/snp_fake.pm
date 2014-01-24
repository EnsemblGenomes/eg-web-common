package Bio::EnsEMBL::GlyphSet::snp_fake;

sub _init {
  my $self   = shift;
  my $config = $self->{'config'};
  my $snps   = $config->{'snps'};
  
  return unless ref $snps eq 'ARRAY'; 
  
  my ($fontname, $fontsize)  = $self->get_font_details('innertext');
  my (undef, undef, $w, $th) = $self->get_text_width(0, 'A', '', font => $fontname, ptsize => $fontsize);
  my $pix_per_bp             = $config->transform->{'scalex'}; 
  my $length                 = exists $self->{'container'}{'ref'} ? $self->{'container'}{'ref'}->length : $self->{'container'}->length; 
  my $tag2                   = $self->my_config('tag') + ($self->strand == -1 ? 1 : 0); 
  
  foreach my $snp_ref (@$snps) { 
    my $snp           = $snp_ref->[2]; 
    my ($start, $end) = ($snp_ref->[0], $snp_ref->[1]);
       $start         = 1       if $start < 1;
       $end           = $length if $end > $length;
    my $label         = $snp->allele_string; 
    my @alleles       = split '/', $label;
    my $h             = 4 + ($th + 2) * scalar @alleles;
    my @res           = $self->get_text_width(($end - $start + 1) * $pix_per_bp, $label =~ /\w\/\w/ ? 'A/A' : $label, 'A', font => $fontname, ptsize => $fontsize);
    
    if ($res[0] eq $label || $res[0] eq 'A/A' || $res[0] eq '') {
      my $tmp_width = ($w * 2 + $res[2]) / $pix_per_bp;
         $h         = 8 + $th * 2;
      
      if ((abs($end - $start) + 1) > $tmp_width) {
	      $start = ($end + $start - $tmp_width) / 2;
	      $end   = $start + $tmp_width;
      }
      
      @res = $self->get_text_width(($end - $start + 1) * $pix_per_bp, $label, '', font => $fontname, ptsize => $fontsize) if $res[0] ne $label;
      
      $self->push($self->Text({
        x         => ($end + $start - 1 - $res[2] / $pix_per_bp) / 2,
        y         => ($h - $th) / 2,
        width     => $res[2] / $pix_per_bp,
        textwidth => $res[2],
        height    => $th,
        font      => $fontname,
        ptsize    => $fontsize,
        colour    => 'black',
        text      => $res[0] eq '' ? '' : $label, # for an allele like GT/AK/RK, as it's too long, we can't fit it in so show '' label instead
        absolutey => 1,
      }));
    } elsif ($res[0] eq 'A' && $label =~ /^[-\w](\/[-\w])+$/) {
      for (my $i = 0; $i < 3; $i++) {
        my @res       = $self->get_text_width(($end - $start + 1) * $pix_per_bp, $alleles[$i], '', font => $fontname, ptsize => $fontsize);
        my $tmp_width = $res[2] / $pix_per_bp;
        
	      $self->push($self->Text({
          x         => ($end + $start  - 1 - $tmp_width) / 2,
          y         => 3 + ($th + 2) * $i,
          width     => $tmp_width,
          textwidth => $res[2],
          height    => $th,
          font      => $fontname,
          ptsize    => $fontsize,
          colour    => 'black',
          text      => $alleles[$i],
          absolutey => 1,
				}));
      }
    }
    
    my $colour   = $self->get_colour($snp);
    my $tag_root = $snp->dbID; 
    my $tglyph   = $self->Rect({
      x            => $start - 1,
      y            => 0,
      bordercolour => $colour,
      absolutey    => 1,
      href         => $self->href($snp),
      height       => $h,
      width        => $end - $start + 1,
    });
    
    $self->join_tag($tglyph, "X:$tag_root=$tag2", 0.5, 0, $colour, '', -3);
    $self->push($tglyph);
    
    $self->{'legend'}{'variation_legend'}{$snp->display_consequence} ||= $colour;
  }
}

1;
