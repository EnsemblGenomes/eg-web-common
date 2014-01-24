package EnsEMBL::Web::ViewConfig::Gene::Compara_Alignments;
# EG : change default flanking from 600 to 60
sub init {
  my $view_config = shift;

  my $defaults   = {
    flank5_display   =>     60,
    flank3_display   =>     60,
    exon_display     =>     'core',
    exon_ori         =>     'all',
    snp_display      =>     'off',
    line_numbering   =>     'off',
    display_width    =>     120,
    conservation_display  =>  'on',
    region_change_display => 'off',
    codons_display        => 'off',
    title_display         => 'off'
  };

  $view_config->set_defaults($defaults);
  
  #$view_config->storable;
  #$view_config->nav_tree = 1;
  
  my $hash = $view_config->species_defs->multi_hash->{'DATABASE_COMPARA'}{'ALIGNMENTS'}||{};
  
  foreach my $row_key (grep { $hash->{$_}{'class'} !~ /pairwise/ } keys %$hash) {
    my %hash_conf = map {( lc("species_${row_key}_$_"), /Ancestral|merged/ ? 'off' : 'yes' )} keys %{$hash->{$row_key}{'species'}}; 
    $view_config->set_defaults(\%hash_conf);
  }
}

1;
