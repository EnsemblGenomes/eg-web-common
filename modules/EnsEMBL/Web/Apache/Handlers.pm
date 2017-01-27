=head1 LICENSE

Copyright [2009-2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Apache::Handlers;

use strict;
use warnings;

sub http_redirect {
  ## Perform an http redirect
  ## @param Apache2::RequestRec request object
  ## @param URI string to redirect to
  ## @param Flag kept on for permanent redirects
  ## @return HTTP_MOVED_TEMPORARILY or HTTP_MOVED_PERMANENTLY
  my ($r, $redirect_uri, $permanent) = @_;
  $r->uri($redirect_uri);
  $r->headers_out->add('Location' => $r->uri);
  ## EG -- We don't belive this is really needed and removing this improved server performance a lot.
  #$r->child_terminate; # TODO really needed?

  return $permanent ? HTTP_MOVED_PERMANENTLY : HTTP_MOVED_TEMPORARILY;
}

1;
