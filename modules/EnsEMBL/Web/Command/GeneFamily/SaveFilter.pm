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

package EnsEMBL::Web::Command::GeneFamily::SaveFilter;

use strict;
use Compress::Zlib;

use base qw(EnsEMBL::Web::Command);

sub process {
  my $self           = shift;
  my $hub            = $self->hub;
  my $session        = $hub->session;
  my $redirect       = $hub->param('redirect') || $hub->species_path($hub->data_species);
  my $gene_family_id = $hub->param('gene_family_id');
  my @species        = $hub->param('s');
 

  my $data = {
    type   => 'genefamilyfilter', 
    code   => $hub->data_species . '_' . $gene_family_id,
    filter => compress( join(',', @species) ),
  };

  $session->set_record_data($data);

  $self->hub->redirect($redirect);  
}

1;
