package EnsEMBL::Web::Component::Gene::GeneSpliceImageNew;

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component::Gene::GeneSNPImageSplice);

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  1 );
}

sub caption {
  return undef;
}

sub content {
  return $_[0]->_content(1, 'GeneSpliceView');
}

1;

