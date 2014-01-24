package Bio::EnsEMBL::GlyphSet::bam;
use strict;
use base qw(Bio::EnsEMBL::GlyphSet::sequence);

# get the alignment features
sub features {
  my $self = shift;

  my $slice = $self->{'container'};

  if (!exists($self->{_cache}->{features})) {

    $self->{_cache}->{features} = $self->bam_adaptor->fetch_alignments_filtered($slice->seq_region_name, $slice->start, $slice->end);

    # unless region name exists, check synonyms
    if ( ref $self->{_cache}->{features} eq 'ARRAY' && !@{$self->{_cache}->{features}} ){

      my $synonym_obj = $slice->get_all_synonyms(); # arrayref of Bio::EnsEMBL::SeqRegionSynonym objects
      my $features;
      foreach my $synonym (@$synonym_obj) {
        $features =  $self->bam_adaptor->fetch_alignments_filtered($synonym->name, $slice->start, $slice->end);
        last if (ref $features eq 'ARRAY' && @$features > 0);
      }
      $self->{_cache}->{features} = $features || [];
    }  
  }

  return $self->{_cache}->{features};
}

1;
