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

package EnsEMBL::Web::Document::Page;

use strict;
use URI::Escape;

sub ajax_redirect {
  my ($self, $url, $redirect_type, $modal_tab) = @_;
  
  my $r         = $self->renderer->{'r'};
  my $back      = $self->{'input'}->param('wizard_back');
  my @backtrack = map $url =~ /_backtrack=$_\b/ ? () : $_, $self->{'input'}->param('_backtrack');
  
  $url .= ($url =~ /\?/ ? ';' : '?') . '_backtrack=' . join ';_backtrack=', @backtrack if scalar @backtrack;
  $url .= ($url =~ /\?/ ? ';' : '?') . "wizard_back=$back" if $back;

## EG - ENSEMBL-3972 the url seems to get decoded somewhere on the other side so we need to encode here.
##      this (or an equiv fix) needs to go into core        
##      REMOVE FOR EG29 as now fixed by ENSWEB-1510 in E82   
  $url = uri_escape($url) unless $url =~ /ensembl\.org\/index\.html$/; # regex is a hack to make login work :/
##

  if ($self->renderer->{'_modal_dialog_'}) {
    if (!$self->{'ajax_redirect_url'}) {
      $self->{'ajax_redirect_url'} = $url;
      $redirect_type ||= 'modal';
      $modal_tab     ||= '';

      $r->content_type('text/plain');
      print qq({"redirectURL":"$url", "redirectType":"$redirect_type", "modalTab":"$modal_tab"});
    }
  } else {
    $r->headers_out->set('Location' => $url);
    $r->status(Apache2::Const::REDIRECT);
  }
}

1
