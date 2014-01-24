package Bio::EnsEMBL::GlyphSet::_variation;

sub highlight {
  my $self = shift; 
  my ($f, $composite, $pix_per_bp, $h, $hi_colour) = @_;

  return if $self->my_config('style') && ($self->my_config('style') ne 'box'); 
  
  ## Get highlights
  my %highlights;
  @highlights{$self->highlights} = (1);

  if ($self->{'config'}->core_objects->{'variation'}){
    my $var_id = $self->{'config'}->core_objects->{'variation'}->name;
    $var_id =~ s/rs//;  
    $highlights{$var_id} = 1;
  }

  # Are we going to highlight self item
  my $id = $f->variation_name;  
     $id =~ s/^rs//;
 
  return unless $highlights{$id} || $highlights{"rs$id"};
 
  
  $self->unshift(
    $self->Rect({ # First a black box
      x         => $composite->x - 3/$pix_per_bp,
      y         => $composite->y - 1, # + makes it go down
      width     => $composite->width + 6/$pix_per_bp,
      height    => $h + 4,
      colour    => 'black',
      absolutey => 1,
    }),
    $self->Rect({ # Then a 1 pixel smaller white box
      x         => $composite->x - 2/$pix_per_bp,
      y         => $composite->y, # + makes it go down
      width     => $composite->width + 4/$pix_per_bp,
      height    => $h + 2,
      colour    => 'white',
      absolutey => 1,
    })
  );
}

sub render_histogram {
    my $self = shift;

    my $h           = 20;
    my $colour      = $self->my_config('col')  || 'gray50';
    my $line_colour = $self->my_config('line') || 'red';
    my $slice = $self->{'container'};
    my $scalex = $self->scalex;

    my $density = $self->features_density();

    my $maxvalue = (sort {$b <=> $a} values %$density)[0];

    return $self->render_normal if ($maxvalue == 1);

    foreach my $pos (sort {$a <=> $b} keys %$density) {
	my $v = $density->{$pos};
	my $h1 = int(($v / $maxvalue) * $h);
	$self->push($self->Line({
	    x         => $pos,
	    y         => $h - $h1,
	    width     => 0,
	    height    => $h1,
	    colour    => $colour,
	    absolutey => 1,
	    absolutex => 1
	})); 
    }
      
    my( $fontname_i, $fontsize_i ) = $self->get_font_details( 'innertext' );
    my @res_i = $self->get_text_width(0, $maxvalue, '', 'font'=>$fontname_i, 'ptsize' => $fontsize_i );
    my $textheight_i = $res_i[3];

   $self->push( $self->Text({
	'text'          => $maxvalue,
	'width'         => $res_i[2],
	'textwidth'     => $res_i[2],
	'font'          => $fontname_i,
	'ptsize'        => $fontsize_i,
	'halign'        => 'right',
	'valign'        => 'top',
	'colour'        => $line_colour,
	'height'        => $textheight_i,
	'y'             => 0,
	'x'             => -4 - $res_i[2],
	'absolutey'     => 1,
	'absolutex'     => 1,
	'absolutewidth' => 1,
    }));

    $maxvalue = ' 0';
    @res_i = $self->get_text_width(0, $maxvalue, '', 'font'=>$fontname_i, 'ptsize' => $fontsize_i );
    $textheight_i = $res_i[3];
    
   $self->push( $self->Text({
	'text'          => $maxvalue,
	'width'         => $res_i[2],
	'textwidth'     => $res_i[2],
	'font'          => $fontname_i,
	'ptsize'        => $fontsize_i,
	'halign'        => 'right',
	'valign'        => 'bottom',
	'colour'        => $line_colour,
	'height'        => $textheight_i,
	'y'             => $textheight_i + 4,
	'x'             => -4 - $res_i[2],
	'absolutey'     => 1,
	'absolutex'     => 1,
	'absolutewidth' => 1,
    }));
}

sub features_density {
    my $self = shift;
    my $slice = $self->{'container'};
    my $START = $self->{'container'}->start - 1;
    my $snps = $self->fetch_features() || return {};
    my $density = {};
    my $scalex = $self->scalex;
   
# check if we display proper B:E:Variation ( those are already mapped to the slice and have method 'start')
    if ($snps->[0] && $snps->[0]->can('start')) {
	foreach my $snp (@{$snps||[]}) {
	    my $vs = int($snp->start * $scalex);
	    $density->{$vs}++;
	}
    } else {
	foreach my $snp (@{$snps||[]}) {
	    my $vs = int(($snp->{START} - $START) * $scalex);
	    $density->{$vs}++;
	}
    }
    return $density;
}

1;
