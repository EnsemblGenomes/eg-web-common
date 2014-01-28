=head1 LICENSE

Copyright [2009-2014] EMBL-European Bioinformatics Institute

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

# $Id: SSI.pm,v 1.1 2013-05-13 11:21:37 jh15 Exp $

package EnsEMBL::Web::Controller::SSI;

use strict;


sub template_SPECIESDEFS {
  my ($self,$var)=@_;
  return $self->species_defs->$var;
}

1;
