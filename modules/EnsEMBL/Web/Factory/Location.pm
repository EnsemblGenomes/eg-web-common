=head1 LICENSE

Copyright [2009-2022] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Factory::Location;

sub _create_from_slice {
  my ($self, $type, $id, $slice, $real_chr) = @_;
  
  my $location;
  
  if ($slice) {
    my $projection = $slice->project($self->__level);
    
    if ($projection) {
      my ($projected_slice) = map $_->[2]->is_reference ? $_->[2] : (), @$projection;
      
      $slice = $projected_slice || $projection->[0][2];
      
      my $start  = $slice->start;
      my $end    = $slice->end;
      my $region = $slice->seq_region_name;
      
      if ($slice->seq_region_name ne $real_chr) {
        my $feat = Bio::EnsEMBL::Feature->new(
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
## EG
      $location = $self->new_location($slice, $type);
##      
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
  
  if ($slice->start > $slice->end && !$slice->is_circular) {
    $self->problem('fatal', 'Invalid location',
      sprintf 'The start position of the location you have entered <strong>(%s:%s-%s)</strong> is greater than the end position.', $slice->seq_region_name, $self->thousandify($slice->start), $self->thousandify($slice->end)
    );
    
    return undef;
  }

## EG
  $type ||= '';

  my $start = $slice->start;
  my $end   = $slice->end;

  if (lc($type) =~ /contig/) {
    my $threshold   = 1000100 * ($self->species_defs->ENSEMBL_GENOME_SIZE||1);
    my $mid =  $start + int(($end - $start)/2);
    $start =  int($mid - ($threshold/2)) > $start ? int($mid - ($threshold/2)) : $start;
    $end   =  int($mid + ($threshold/2)) < $end   ? int($mid + ($threshold/2)) : $end;
  } 
## EG

  my $location = $self->new_object('Location', {
    type               => 'Location',
    real_species       => $self->__species,
    name               => $slice->seq_region_name,
    seq_region_name    => $slice->seq_region_name,
## EG
    seq_region_start   => $start, 
    seq_region_end     => $end,   
##
    seq_region_strand  => 1,
    seq_region_type    => $slice->coord_system->name,
    raw_feature_strand => 1,
    seq_region_length  => $slice->seq_region_length
  }, $self->__data);
  
  $location->attach_slice($slice);
  
  return $location;
}

1;
