package EnsEMBL::Web::Component::Transcript::S4DAS;

use strict;
use warnings;

use base qw(EnsEMBL::Web::Component::Gene::S4DAS);

sub _das_query_object {
  my $self = shift;
  return $self->object->Obj->translation;
}

1;