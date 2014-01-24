# $Id: ZMenu.pm,v 1.6 2013-12-06 11:31:19 nl2 Exp $

package EnsEMBL::Web::ZMenu;

use strict;

use previous qw(render);

# Build and print the JSON response
sub render {
  my $self = shift;
  my $callback = $self->hub->param('callback');
  
#EG enable cross-origin response via JSON using JSONP (ENSEMBL-2060 @ release 17-70 Feb 2013)
  if ($callback) {
    print $self->hub->param('callback') . '(';
    $self->PREV::render;
    print ');';
  } else {
    $self->PREV::render;
  }
}

1;
