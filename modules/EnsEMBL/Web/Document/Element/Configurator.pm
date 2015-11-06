=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Document::Element::Configurator;

use strict;

use HTML::Entities qw(encode_entities);

sub add_image_config_notes {
  my ($self, $controller) = @_;
  my $panel   = $self->new_panel('Configurator', $controller, code => 'x', class => 'image_config_notes' );
  my $img_url = $self->img_url;
  my $trackhub_link = $self->hub->url({'type' => 'UserData', 'action' => 'SelectHub'});
  
  $panel->set_content(
## EG - ENSEMBL-4038 hide link to 'Track Hub list' as we don't have one  
#  qq(
#    <div class="info-box">
#    <p>Looking for more data? See our <a href="${trackhub_link}" class="modal_link">Track Hub list</a> for external sources of annotation</p>
#    </div>
##
  qq(
    <h2 class="border clear">Key</h2>
    <div>
      <ul class="configuration_key">
        <li><img src="${img_url}render/normal.gif" /><span>Track style</span></li>
        <li><img src="${img_url}strand-f.png" /><span>Forward strand</span></li>
        <li><img src="${img_url}strand-r.png" /><span>Reverse strand</span></li>
        <li><img src="${img_url}star-on.png" /><span>Favourite track</span></li>
        <li><img src="${img_url}16/info.png" /><span>Track information</span></li>
      </ul>
    </div>
    <div>
      <ul class="configuration_key">
        <li><img src="${img_url}track-external.gif" /><span>External data</span></li>
        <li><img src="${img_url}track-user.gif" /><span>User-added track</span></li>
      </ul>
    </div>
    <p class="border space-below">Please note that the content of external tracks is not the responsibility of the Ensembl project.</p>
    <p>URL-based or DAS tracks may either slow down your ensembl browsing experience OR may be unavailable as these are served and stored from other servers elsewhere on the Internet.</p>
  ));

  $self->add_panel($panel);
}

1;
