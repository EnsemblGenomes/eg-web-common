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

package EnsEMBL::Web::Component::Help::View;

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $adaptor = EnsEMBL::Web::DBSQL::WebsiteAdaptor->new($hub);
  foreach (@{$adaptor->fetch_help_by_ids([$hub->param('id')])}){
    my $content = $self->parse_help_html($_->{'content'}, $adaptor);
    $content =~ s/href="[.\/]*Homo_sapiens/href="http:\/\/www.ensembl.org\/Homo_sapiens/ig;
    $content =~ s/Scrolling over the inverted triangle/ Clicking on the inverted triangle/ig; 
    return $content;
  }
}

1;
