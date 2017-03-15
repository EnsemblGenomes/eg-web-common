=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2017] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::File::AttachedFormat::TRACKHUB;

use strict;
use warnings;

use previous qw(check_data);

## EG - Hack to fix ENSEMBL-4841
##      Don't validate against the assembly lookup as we already did this when
##      the user chose the hub. If the hub was matched using a THR assembly 
##      synonym, it will fail the assembly check here because we don't have the 
##      synonyms available at this stage.

sub check_data {
  my ($self, $assembly_lookup) = @_;
  return $self->PREV::check_data(undef); # <-- intentionally not passing $assembly_lookup here
}

1;
