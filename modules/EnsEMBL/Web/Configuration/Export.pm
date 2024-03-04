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

# $Id: Export.pm,v 1.2 2011-02-15 17:59:19 it2 Exp $

package EnsEMBL::Web::Configuration::Export;

sub modify_tree {
  my $self = shift; 
  my %config = ( availability => 1, no_menu_entry => 1 );
  $self->create_node("VCFView", '', [ 'vcf_view', 'EnsEMBL::Web::Component::Export::VCFView' ], \%config);  
}

1;
