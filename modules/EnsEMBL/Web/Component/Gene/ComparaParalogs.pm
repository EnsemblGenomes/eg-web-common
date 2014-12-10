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

package EnsEMBL::Web::Component::Gene::ComparaParalogs;

use strict;

our %button_set = ('download' => 1, 'view' => 0);

sub buttons {
  my $self    = shift;
  my $hub     = $self->hub;
  my @buttons;

  if ($button_set{'download'}) {

    my $gene    =  $self->object->Obj;

    my $dxr  = $gene->can('display_xref') ? $gene->display_xref : undef;
    my $name = $dxr ? $dxr->display_id : $gene->stable_id;

    my $params  = {
                  'type'        => 'DataExport',
                  'action'      => 'Paralogs',
                  'data_type'   => 'Gene',
                  'component'   => 'ComparaParalogs',
                  'data_action' => $hub->action,
                  'gene_name'   => $name,
                };

    push @buttons, {
                    'url'     => $hub->url($params),
                    'caption' => 'Download paralogues',
                    'class'   => 'export',
                    'modal'   => 1
                    };
  }

  if ($button_set{'view'}) {

    my $cdb = $hub->param('cdb') || 'compara';

    my $params = {
                  'action' => 'Compara_Paralog',
                  'function' => 'Alignment'.($cdb =~ /pan/ ? '_pan_compara' : ''),
                  };

    push @buttons, {
                    'url'     => $hub->url($params),
## EG change caption                  
                    'caption' => 'View protein alignments of all paralogues',
##
                    'class'   => 'view',
                    'modal'   => 0
    };
  }
  return @buttons;
}
1;

