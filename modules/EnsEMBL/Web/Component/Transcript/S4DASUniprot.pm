package EnsEMBL::Web::Component::Transcript::S4DASUniprot;

use strict;
use warnings;

use base qw(EnsEMBL::Web::Component::Gene::S4DASUniprot);

sub _das_query_object {
  my $self = shift;
  return $self->object->Obj->translation;
}

1;