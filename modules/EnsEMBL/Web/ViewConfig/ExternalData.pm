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

# $Id: ExternalData.pm,v 1.2 2011-03-25 17:06:10 nl2 Exp $

package EnsEMBL::Web::ViewConfig::ExternalData;

use strict;

sub form {
  my ($view_config, $object) = @_;
  
  $view_config->add_fieldset('DAS sources');
  
  my $view    = $object->__objecttype . '/ExternalData';
  my @all_das = sort { lc $a->label cmp lc $b->label } grep {$_->is_on($view) and $_->renderer !~ /^S4DAS/} values %{$view_config->hub->get_all_das};
  
  foreach my $das (@all_das) {
    $view_config->add_form_element({
      type  => 'DASCheckBox',
      das   => $das,
      name  => $das->logic_name,
      value => 'yes'
    });
  }
}

1;
