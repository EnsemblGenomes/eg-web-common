package EnsEMBL::Draw::GlyphSet::bam;

use strict;
use Bio::EnsEMBL::Feature;

sub features {
## get the alignment features
  my $self = shift;

  my $slice = $self->{'container'};
  if (!exists($self->{_cache}->{features})) {
## EG support seq region synonyms    
    my $seq_region_names = [$slice->seq_region_name];
    push @$seq_region_names, map {$_->name} @{ $slice->get_all_synonyms };

    my $data;
    foreach my $seq_region_name (@$seq_region_names) {
      $data = $self->bam_adaptor->fetch_alignments_filtered($seq_region_name, $slice->start, $slice->end) || [];
      last if @$data;
    } 

    $self->{_cache}->{features} = $data;
##
  }

  # $self->{_cache}->{features} ||= $self->bam_adaptor->fetch_alignments_filtered($slice->seq_region_name, $slice->start, $slice->end);

  return $self->{_cache}->{features};
}

sub consensus_features {
## get the consensus features
  my $self = shift;
 
  unless ($self->{_cache}->{consensus_features}) {
    my $slice = $self->{'container'};
    my $START = $self->{'container'}->start;
## EG support seq region synonyms   
    my $seq_region_names = [$slice->seq_region_name];
    push @$seq_region_names, map {$_->name} @{ $slice->get_all_synonyms };

    my $consensus;
    foreach my $seq_region_name (@$seq_region_names) {
      $consensus = $self->bam_adaptor->fetch_consensus($seq_region_name, $slice->start, $slice->end) || [];
      last if @$consensus;
    }    
##    
    my @features;
    
    foreach my $a (@$consensus) {
      my $x = $a->{x} - $START+1;
      my $feat = Bio::EnsEMBL::Feature->new_fast( {
                         'start' => $x,
                         'end' => $x,
                         'strand' => 1,
                         'seqname' => $a->{bp},
                        } );

#      my $feat = Bio::EnsEMBL::Feature->new( 
#        -start => $x,
#        -end => $x,
#        -strand => 1,
#        -seqname => $a->{bp},
#      );

#     push @features, $feat;

      $features[$x-1] = $feat;
    }

    
    $self->{_cache}->{consensus_features} = \@features;
  }
  
  return $self->{_cache}->{consensus_features};
}

1;
