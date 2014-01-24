package Bio::EnsEMBL::GlyphSet::_marker;

## This is here to fix https://www.ebi.ac.uk/panda/jira/browse/VB-2047
## I've sent a patch to Ensembl webteam - hopefully we can drop this plugin for E73

use strict;

sub features {
  my $self  = shift;
  my $slice = $self->{'container'};
  my @features;
  
  if ($self->{'text_export'}) {
    @features = @{$slice->get_all_MarkerFeatures};
  } else {
    my $priority   = $self->my_config('priority');
    my $marker_id  = $self->my_config('marker_id');
    my $map_weight = 2;
## EG  
       @features   = @{$slice->get_all_MarkerFeatures(undef, $priority, $map_weight)};
    
    # only add the highlighted marker if not already present
    push @features, @{$slice->get_MarkerFeatures_by_Name($marker_id)} if $marker_id and !grep {$_->display_id eq $marker_id} @features; ## Force drawing of specific marker regardless of weight
##
  }
  
  foreach my $f (@features) {
    my $ms  = $f->marker->display_MarkerSynonym;
    my $id  = $ms ? $ms->name : '';
      ($id) = grep $_ ne '-', map $_->name, @{$f->marker->get_all_MarkerSynonyms || []} if $id eq '-' || $id eq '';
    
    $f->{'drawing_id'} = $id;
  }
  
  return [ sort { $a->seq_region_start <=> $b->seq_region_start } @features ];
}

1;
