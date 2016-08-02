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

package EnsEMBL::Web::Component::Tools::Blast::InputForm;

use strict;
use warnings;
use URI;
use previous qw(get_cacheable_form_node);
use List::Util qw(min);

sub get_cacheable_form_node {
  my $self            = shift;
  my $form      = $self->new_tool_form({'class' => 'blast-form'});

  $form->append_child('div', {

      'children'    => [{
        'node_name'   => 'h2',
        'inner_HTML'  => 'Temporarily unavailable'
      }, {
      'node_name'   => 'p',
      'inner_HTML'  => 'BLAST search is temporarily unavailable. We are working to resolve the issues and will restore this service as soon as possible.'
    }]
    }
  );

  return $form;

}

1;
