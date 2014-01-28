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

package EnsEMBL::Web::Factory::Feature;

use strict;
use warnings;
no warnings 'uninitialized';

sub _create_Gene {
  ### Fetches all the genes for a given identifier (usually only one, but could be multiple
  ### Args: db
  ### Returns: hashref containing a Data::Bio::Gene object
  
  my ($self, $db) = @_;
## EG
  #my $genes       = $self->_generic_create('Gene', $self->param('id') =~ /^ENS/ ? 'fetch_by_stable_id' : 'fetch_all_by_external_name', $db);
  my $genes;
  eval { $genes = $self->_generic_create('Gene', 'fetch_by_stable_id', $db) };
  eval { $genes = $self->_generic_create('Gene', 'fetch_all_by_external_name', $db) } if !$genes;
 
  return { Gene => EnsEMBL::Web::Data::Bio::Gene->new($self->hub, @{$genes || []}) };
## 
}

1;
