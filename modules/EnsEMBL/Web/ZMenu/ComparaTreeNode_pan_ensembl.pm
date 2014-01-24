package EnsEMBL::Web::ZMenu::ComparaTreeNode_pan_ensembl;

use strict;

use base qw(EnsEMBL::Web::ZMenu::ComparaTreeNode);

sub content {
      my $self = shift;
      my $cdb = 'compara_pan_ensembl';
      $self->SUPER::content($cdb);
}

1;
