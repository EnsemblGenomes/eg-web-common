# $Id: contigviewbottom.pm,v 1.7 2013-11-27 14:23:52 ek3 Exp $

package EnsEMBL::Web::ImageConfig::contigviewbottom;

use strict;

sub modify {
  my $self = shift;
  
  $self->load_configured_bam;
  $self->load_configured_bed;
  $self->load_configured_bedgraph;
  $self->load_configured_mw;
} 

1;
