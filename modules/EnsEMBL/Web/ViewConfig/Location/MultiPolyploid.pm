=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::ViewConfig::Location::MultiPolyploid;

use base qw(EnsEMBL::Web::ViewConfig);

sub init {
  my $self = shift;

  $self->set_defaults({
    show_bottom_panel => 'yes'
  });
  
  $self->add_image_config('MultiBottom');
  $self->title = 'Polyploid view';
  
  $self->set_defaults({
    opt_pairwise_blastz   => 'normal',
    opt_pairwise_tblat    => 'normal',
    opt_pairwise_lpatch   => 'normal',
    opt_join_genes_bottom => 'off',
  });
}

1;
