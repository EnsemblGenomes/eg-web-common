package EnsEMBL::Web::Text::Feature;

use strict;
use warnings;
no warnings "uninitialized";

sub map {
  my( $self, $slice ) = @_;
  my $chr = $self->seqname(); 
  $chr=~s/^chr//;

  # $chr is imported chr name, $slice->seq_region_name defaults to '01'
  my $synonym_obj = $slice->get_all_synonyms();
  my @syns;
  
  push @syns, grep { $_ eq $chr}
    map { $_->name } @$synonym_obj;
  
  # if imported chr name not equal default name or synonym name
  # no data available

  return () if ($chr ne $slice->seq_region_name && !@syns);

  my $start = $self->rawstart();
  my $slice_end = $slice->end();
  return () unless $start <= $slice_end;
  my $end   = $self->rawend();
  my $slice_start = $slice->start();
  return () unless $slice_start <= $end;
  $self->slide( 1 - $slice_start );
  
  if ($slice->strand == -1) {
    my $flip = $slice->length + 1;
    ($self->{'start'}, $self->{'end'}) = ($flip - $self->{'end'}, $flip - $self->{'start'});
  }
  
  return $self;
}

1;
