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

package EnsEMBL::Web::Document::Panel;

sub _caption_with_helplink {
    my $self    = shift;
    my $img_url = $self->hub ? $self->img_url : undef;
    my $id      = $self->{'help'};

    my $caption = $self->{'caption'};
    if ( $caption =~ /(Gene|Transcript): (\S+) \((.+?)\)/ ) {
      if ($2 eq $3) {
        $caption =~ s/ \(.+?\)//;
      }
    }

    my $html    = '<h2 class="caption">';
    $html      .= sprintf ' <a href="/Help/View?id=%s" class="popup help-header constant" title="Click for Help">', encode_entities($id) if $id;
    $html      .= $caption;
    $html      .= sprintf ' <img src="%shelp-button.png" style="width:40px;height:20px;padding-left:4px;vertical-align:middle" alt="(e?)" class="print_hide" /></a>', $img_url if $id && $img_url;
    $html      .= '</h2>';

    return $html;
}

1;
