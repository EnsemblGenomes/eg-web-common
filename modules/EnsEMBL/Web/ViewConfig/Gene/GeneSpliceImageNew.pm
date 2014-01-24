# $Id: GeneSpliceImageNew.pm,v 1.1 2011-09-21 10:46:53 it2 Exp $

package EnsEMBL::Web::ViewConfig::Gene::GeneSpliceImageNew;

use strict;

use base qw(EnsEMBL::Web::ViewConfig);

sub init {
    my $self = shift;
    $self->add_image_config('GeneSpliceView', 'nodas');
}

1;
