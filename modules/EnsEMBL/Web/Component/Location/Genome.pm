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

package EnsEMBL::Web::Component::Location::Genome;

use strict;
use previous qw(content _configure_Gene_table);

## EG - add warning about unassembled genome
sub content {
  my $self = shift;
  my $html;
  my $chromosomes  = $self->hub->species_defs->ENSEMBL_CHROMOSOMES || [];
  
  if (!scalar @$chromosomes) {
    $html = $self->_info('Unassembled genome', '<p>This genome has yet to be assembled into chromosomes</p>');
  }
  
  $html .= $self->PREV::content(@_);

  return $html;
}

## EG - add datatable config for domains
sub _configure_Gene_table {
  my $self = shift;
  
  my $config = $self->PREV::_configure_Gene_table(@_);

  $config->{table_style} =  {data_table_config => {iDisplayLength => 25}} if $self->hub->param('ftype') eq 'Domain';

  return $config;
}

1;