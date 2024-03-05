=head1 LICENSE

Copyright [2009-2024] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

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
