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

package EnsEMBL::Web::Configuration::UserData;

use strict;

sub modify_tree {
  my $self = shift;

  my $tools_menu = $self->create_submenu('Conversion', 'Online Tools');

  # Add nodes for data slicer tool 

  $tools_menu->append(
    $self->create_node( 'SelectSlice', "Data Slicer",
     [qw(select_vcf EnsEMBL::Web::Component::UserData::SelectSlice)], { 'availability' => 1 }
  ));

  $tools_menu->append(
    $self->create_node( 'SliceFile', '',
      [], { 'command' => 'EnsEMBL::Web::Command::UserData::SliceFile', 'availability' => 1, 'no_menu_entry' => 1 }
  ));

  $tools_menu->append(
    $self->create_node( 'SliceFeedback', '',
     [qw(vcf_feedback EnsEMBL::Web::Component::UserData::SliceFeedback)], { 'availability' => 1, 'no_menu_entry' => 1 }
  ));
}



1;
