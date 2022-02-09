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

package Bio::EnsEMBL::Slice;

sub expand {
    my $self              = shift;
    my $five_prime_shift  = shift || 0;
    my $three_prime_shift = shift || 0;
    my $force_expand      = shift || 0;
    my $fpref             = shift;
    my $tpref             = shift;

    if ( $self->{'seq'} ) {
    warning(
	    "Cannot expand a slice which has a manually attached sequence ");
    return undef;
}
    #for slices of a smaller length:
    if ($self->seq_region_length() < ($five_prime_shift + $three_prime_shift)) {
	$five_prime_shift = int($self->seq_region_length() / 3);
        $three_prime_shift = int($self->seq_region_length() / 3);
    }

    my $sshift = $five_prime_shift;
    my $eshift = $three_prime_shift;

    if ( $self->{'strand'} != 1 ) {
	$eshift = $five_prime_shift;
	$sshift = $three_prime_shift;
    }

    my $new_start = $self->{'start'} - $sshift;
    my $new_end   = $self->{'end'} + $eshift;

    if (( $new_start <= 0 || $new_start > $self->seq_region_length() || $new_end <= 0 || $new_end > $self->seq_region_length() ) && ( $self->is_circular() ) ) {

	if ( $new_start <= 0 ) {
	    $new_start = $self->seq_region_length() + $new_start;
	}
	if ( $new_start > $self->seq_region_length() ) {
	    $new_start -= $self->seq_region_length();
	}

	if ( $new_end <= 0 ) {
	    $new_end = $self->seq_region_length() + $new_end;
	}
	if ( $new_end > $self->seq_region_length() ) {
	    $new_end -= $self->seq_region_length();
	}
    }

    if ( $new_start > $new_end  && (not $self->is_circular() ) ) {

	if ($force_expand) {
          # Apply max possible shift, if force_expand is set                                                                          
	  if ( $sshift < 0 ) {
          # if we are contracting the slice from the start - move the                                                                                                                                            
          # start just before the end                                                                                                                                                                            
	    $new_start = $new_end - 1;
	    $sshift    = $self->{start} - $new_start;
	  }

	  if ( $new_start > $new_end ) {
          # if the slice still has a negative length - try to move the                                                                                                                                           
          # end                                                                                                                                                                      
	    if ( $eshift < 0 ) {
	      $new_end = $new_start + 1;
	      $eshift  = $new_end - $self->{end};
	    }
	  }
          # return the values by which the primes were actually shifted                                                                                                                                     
	  $$tpref = $self->{strand} == 1 ? $eshift : $sshift;
	  $$fpref = $self->{strand} == 1 ? $sshift : $eshift;
	}
	if ( $new_start > $new_end ) {
	    throw('Slice start cannot be greater than slice end');
	}
    }

    my %new_slice;

    if ($new_start > $new_end  && ($self->is_circular() ) && (ref($self) !~ /CircularSlice/) ) {
        my $circsl= Bio::EnsEMBL::CircularSlice->new(-COORD_SYSTEM   => $self->coord_system(),
                                             -SEQ_REGION_NAME    => $self->seq_region_name(),
                                             -SEQ_REGION_LENGTH  => $self->seq_region_length(),
                                             -START              => int($new_start),
                                             -END                => int($new_end),
                                             -STRAND             => $self->strand,
					     -ADAPTOR            => $self->adaptor);
        %new_slice = %$circsl;
        return bless \%new_slice, ref($circsl);
    } else {
        #fastest way to copy a slice is to do a shallow hash copy                                                                                               
        %new_slice = %$self;
        $new_slice{'start'} = int($new_start);
        $new_slice{'end'}   = int($new_end);
        return bless \%new_slice, ref($self);
    }

} ## end sub expand                                  
1;
