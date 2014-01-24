package Bio::EnsEMBL::GlyphSet::snp_join;

sub _init {
  my $self        = shift; 
  my $strand_flag = $self->my_config('str');
  my $strand      = $self->strand();
  
  return if ($strand_flag eq 'f' && $strand != 1) || ($strand_flag eq 'r' && $strand == 1);
  
  my $tag       = $self->my_config('tag');
  my $tag2      = $tag + ($strand == -1 ? 1 : 0);
  my $container = exists $self->{'container'}{'ref'} ? $self->{'container'}{'ref'} : $self->{'container'};
  my $length    = $container->length;
  my $colours   = $self->my_config('colours'); 
  
  foreach my $snp_ref (@{$self->get_snps || []}) {
    my $snp      = $snp_ref->[2];
    my $tag_root = $snp->dbID;
    my $type     = lc $snp->display_consequence;
    my $colour   = $colours->{$type}->{'default'};
    my ($s, $e)  = ($snp_ref->[0], $snp_ref->[1]);
    
    $s = 1 if $s < 1;
    $e = $length if $e > $length;
    
    my $tglyph = $self->Space({
      x      => $s - 1,
      y      => 0,
      height => 0,
      width  => $e - $s + 3,
    });
    
    $self->join_tag($tglyph, "X:$tag_root=$tag2", .5, 0, $colour, '',     -3); 
    $self->join_tag($tglyph, "X:$tag_root-$tag",  .5, 0, $colour, 'fill', -3);  
    $self->push($tglyph);
  }
}

1;
