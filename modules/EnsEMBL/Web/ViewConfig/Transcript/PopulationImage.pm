=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::ViewConfig::Location::SequenceAlignment;

use strict;
use warnings;

sub init_form {
  ## Generic form-building method based on fields provided in form_field and field_order methods
  ## @return ViewConfigForm object
  my $self    = shift;
  my $form    = $self->form;
  my $fields  = $self->form_fields || {};

## EG - use new add_field method instead of deprecated add_form_element method
##      the new version is much faster
##      this should be fixed in E87, then we can drop this from EG
  #$form->add_form_element($_) for map $fields->{$_} || (), $self->field_order;
  $form->add_field($_) for map $fields->{$_} || (), $self->field_order;
##

  return $form;
}

1;
