# $Id: SSI.pm,v 1.1 2013-05-13 11:21:37 jh15 Exp $

package EnsEMBL::Web::Controller::SSI;

use strict;


sub template_SPECIESDEFS {
  my ($self,$var)=@_;
  return $self->species_defs->$var;
}

1;
