=head1 LICENSE

Copyright [2009-2022] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::ZMenu::ComparaTreeNode_pan_ensembl;

use strict;

use base qw(EnsEMBL::Web::ZMenu::ComparaTreeNode);

sub content {
      my $self = shift;
      my $cdb = 'compara_pan_ensembl';
      $self->SUPER::content($cdb);
}

1;
