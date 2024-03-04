=head1 LICENSE

Copyright [2009-2024] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::Variation::DBSQL::CompressedGenotypeAdaptor;

# something to do with the way the alleles stored. in EG they allow for N, in e! they dont
sub fetch_all_by_Variation {
    my $self = shift;
    my $variation = shift;

    my $res;
    if(!ref($variation) || !$variation->isa('Bio::EnsEMBL::Variation::Variation')) {
	throw('Bio::EnsEMBL::Variation::Variation argument expected');
    }

    if(!defined($variation->dbID())) {
	warning("Cannot retrieve genotypes for variation without set dbID");
	return [];
    }	
    my $vfa = $self->db->get_VariationFeatureAdaptor();
    if (!$vfa){
	throw("Cannot retrieve genotypes for variation without adaptor set");
	return [];
    }

    my $variation_features = $vfa->fetch_all_by_Variation($variation);
    #foreach of the hitting variation Features, get the Genotype information
    foreach my $vf (@{$variation_features}){
		
		# skip this VF if the start and end are >1 apart
		# they should not be in the compressed table
		next if abs($vf->end - $vf->start) > 1;

		# get the feature slice for this VF
		my $fs = $vf->feature_Slice();
		
		# if the feature slice is start > end
		if($fs->start > $fs->end) {
			
			# get a new slice with the start and end the right way round
			# otherwise the call won't pick any variations up
			my $new_fs = $fs->{'adaptor'}->fetch_by_region($fs->coord_system->name,$fs->seq_region_name,$fs->end,$fs->start);
			$fs = $new_fs;
		}
		
		# get the IGs
		my @igs = @{$self->fetch_all_by_Slice($fs)};
		
		#print "fS: ", $fs->start, " ", $fs->end, "\n";
		
		# iterate through to check
		foreach my $ig(@igs) {
			# skip this if the variation attached to the IG does not match the query

			#next unless $ig->variation->dbID == $variation->dbID;

			push @{$res}, $ig;
		}
		
		# old code without checks
		#map {$_->variation($variation); push @{$res}, $_} @{$self->fetch_all_by_Slice($vf->feature_Slice)};
    }
	
	#print "Got ", (defined $res ? scalar @{$res} : 0), " from single bp\n";
	
    #and include the genotypes from the multiple genotype table
    $self->_multiple(1);
    push @{$res}, @{$self->SUPER::fetch_all_by_Variation($variation)};
    $self->_multiple(0);
	
	#print "Now have ", scalar @{$res}, " including multiple bp\n";
	
    return $res;
}

sub fetch_all_by_Slice{
    my $self = shift;
    my $slice = shift;
    my $individual = shift;
	my $include_multi = shift;
    my @results;
    my $features;
    my $constraint;
    if (!$self->_multiple){
	#if passed inividual or population, add constraint
	if (defined $individual && defined $individual->dbID){
	  my $instr;
	  
	  if($individual->isa("Bio::EnsEMBL::Variation::Population")) {
		my $inds = $individual->get_all_Individuals;
		my @list;
		push @list, $_->dbID foreach @$inds;
		$instr = (@list > 1)  ? " IN (".join(',',@list).")"   :   ' = \''.$list[0].'\'';
		$constraint = " c.sample_id $instr";
	  }
	  else {
		$constraint = ' c.sample_id = ' . $individual->dbID;
	  }
	  
	 # $constraint = ' c.sample_id = ?';
	 # $self->bind_param_generic_fetch($individual->dbID,SQL_INTEGER);
	  $features = $self->SUPER::fetch_all_by_Slice_constraint($slice,$constraint);
	}
	else{
	    $features = $self->SUPER::fetch_all_by_Slice($slice);
	}
	#need to check the feature is within the Slice
	
	my $seq_region_slice = $slice->seq_region_Slice;

	foreach my $indFeature (@{$features}){
	  #print "feature_start ",$indFeature->start," slice_end ",$slice->end," slice_start ",$slice->start," feature_end ",$indFeature->end, " a: ", $indFeature->allele1, "|", $indFeature->allele2, " in ", $indFeature->individual->name, "\n" if ($indFeature->end==1);
	    if ($indFeature->start > 0 && ($slice->end-$slice->start +1) >= $indFeature->end){
		
		# not sure we need this check now???
		#next unless defined $indFeature->variation;
			
		if ($indFeature->slice->strand == -1){ #ignore the different strand transformation

		  # Position will change if the strand is negative so change the strand to 1 temporarily
		    $indFeature->slice->{'strand'} = 1;
		    my $newFeature = $indFeature->transfer($seq_region_slice); 
		    $indFeature->slice->{'strand'} = -1;
		    $newFeature->slice->{'strand'} = -1;
                    $newFeature->variation($indFeature->variation);
		    push @results, $newFeature;
		}
		else{
		    push @results,$indFeature->transfer($seq_region_slice);
		}
	    }
		#else {
		#	print "ignored\n";
		#}
	}
	
	$self->_multiple(1);
	push @results, @{$self->fetch_all_by_Slice($slice,$individual)} if $include_multi;
	$self->_multiple(0);
	
    }
    else{
	#if passed inividual, add constraint
	if (defined $individual && defined $individual->dbID){
	  $constraint = ' ig.sample_id = ' . $individual->dbID;
	 # $constraint = ' c.sample_id = ?';
	 # $self->bind_param_generic_fetch($individual->dbID,SQL_INTEGER);
	  $features = $self->SUPER::fetch_all_by_Slice_constraint($slice,$constraint);
	}
	else{
	    $features = $self->SUPER::fetch_all_by_Slice($slice);
	}
	#and include the genotypes from the multiple genotype table
	push @results, @$features;
    }
	
    return \@results;
    
}

1;
