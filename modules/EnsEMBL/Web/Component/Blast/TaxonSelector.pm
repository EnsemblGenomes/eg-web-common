package EnsEMBL::Web::Component::Blast::TaxonSelector;

use strict;
use warnings;
no warnings 'uninitialized';
use base qw(EnsEMBL::Web::Component::TaxonSelector);

sub _init {
  my $self = shift;
  
  $self->SUPER::_init;
  
  $self->{selection_limit} = 25;
  $self->{is_blast}        = 1;
}

1;
