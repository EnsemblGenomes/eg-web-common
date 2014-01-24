package EnsEMBL::Web::Factory::Location;

sub _create_from_slice {
  my ($self, $type, $id, $slice, $real_chr) = @_;
  
  my $location;
  
  if ($slice) {
    my $projection = $slice->project($self->__level);
    
    if ($projection) {
      my $projected_slice = shift @$projection; # take first element
      
      $slice = $projected_slice->[2];
      
      my $start  = $slice->start;
      my $end    = $slice->end;
      my $region = $slice->seq_region_name;
       
      # take all other elements in case something has gone wrong
      foreach (@$projection) {

        if ($_->[2]->seq_region_name ne $region) {
          $self->problem('fatal', 'Slice does not map to single ' . $self->__level, 'end and start on different seq regions');
          return undef;
        }
        
        $start = $_->[2]->start if $_->[2]->start < $start;
        $end   = $_->[2]->end   if $_->[2]->end   > $end;
      }
      
      if ($slice->seq_region_name ne $real_chr) {

        my $feat = new Bio::EnsEMBL::Feature(
            -start  => 1, 
            -end    => $slice->length, 
            -strand => 1, 
            -slice  => $slice 
        );
        
        my $altlocs = $feat->get_all_alt_locations(1) || [];
        
        foreach my $f (@$altlocs) {
          if ($f->seq_region_name eq $real_chr) {
            $slice = $f->{'slice'} if $f->seq_region_name;
            last;
          }
        }
      }

      $location = $self->new_location($slice, $type);
      
      my $object_types = { %{$self->hub->object_types}, Exon => 'g' }; # Use gene factory to generate tabs when using exon to find location
      
      $self->param($object_types->{$type}, $id) if $object_types->{$type};
    } else {
      $self->problem('fatal', 'Cannot map slice', 'must all be in gaps'); 
    }
  } else {
    $self->problem('fatal', 'Ensembl Error', "Cannot create slice - $type $id does not exist")
  }
  
  return $location;
}

sub new_location {
  my ($self, $slice, $type) = @_;

  $type ||= '';

  my $start = $slice->start;
  my $end   = $slice->end;

  if (lc($type) =~ /contig/) {
    my $threshold   = 1000100 * ($self->species_defs->ENSEMBL_GENOME_SIZE||1);
    my $mid =  $start + int(($end - $start)/2);
    $start =  int($mid - ($threshold/2)) > $start ? int($mid - ($threshold/2)) : $start;
    $end   =  int($mid + ($threshold/2)) < $end   ? int($mid + ($threshold/2)) : $end;
  } 
  
  my $location = $self->new_object('Location', {
    type               => 'Location',
    real_species       => $self->__species,
    name               => $slice->seq_region_name,
    seq_region_name    => $slice->seq_region_name,
    seq_region_start   => $start, 
    seq_region_end     => $end,   
    seq_region_strand  => 1,
    seq_region_type    => $slice->coord_system->name,
    raw_feature_strand => 1,
    seq_region_length  => $slice->seq_region_length
  }, $self->__data);
  
  $location->attach_slice($slice);
  
  return $location;
}

1;
