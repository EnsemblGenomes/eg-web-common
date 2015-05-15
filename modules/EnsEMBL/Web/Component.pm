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

package EnsEMBL::Web::Component;

use strict;
use EnsEMBL::Web::Constants;

sub _export_image {
  my ($self, $image, $flag) = @_;
  my $hub = $self->hub;
  
  $image->{'export'} = 'iexport' . ($flag ? " $flag" : '');
  
  my ($format, $scale) = $hub->param('export') ? split /-/, $hub->param('export'), 2 : ('', 1);
  $scale eq 1 if $scale <= 0;
  
  my %formats = EnsEMBL::Web::Constants::EXPORT_FORMATS;
  
  if ($formats{$format}) {
    $image->drawable_container->{'config'}->set_parameter('sf',$scale);
    (my $comp = ref $self) =~ s/[^\w\.]+/_/g;
    my $filename = sprintf '%s-%s-%s.%s', $comp, $hub->filename($self->object), $scale, $formats{$format}{'extn'};
    
    if ($hub->param('download')) {
      $hub->input->header(-type => $formats{$format}{'mime'}, -attachment => $filename);
    } else {
      $hub->input->header(-type => $formats{$format}{'mime'}, -inline => $filename);
    }

    if ($formats{$format}{'extn'} eq 'txt') {
            # EG:
      print $image->drawable_container->{'export'} || "No data to export.";
            # EG
      return 1;
    }

    $image->render($format);
    return 1;
  }
  
  return 0;
}

1;
