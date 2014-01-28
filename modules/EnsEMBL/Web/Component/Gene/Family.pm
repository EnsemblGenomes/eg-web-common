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

package EnsEMBL::Web::Component::Gene::Family;

sub jalview_link {
  my ($self, $family, $type, $refs, $cdb) = @_;
  my $count = @$refs;
  my $ckey = ($cdb =~ /pan/) ? '_pan_compara' : '';
  my $url   = $self->hub->url({ function => "Alignments$ckey", family => $family });
### EG : we dont have cigar lines for this view
#  return qq(<p class="space-below">$count $type members of this family <a href="$url">JalView</a></p>);
  return qq(<p class="space-below">$count $type members of this family</p>);
}

1;
