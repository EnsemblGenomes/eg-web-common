=head1 LICENSE

Copyright [2009-2022] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Document::Element::Copyright;

### Copyright notice for footer (basic version with no logos)

use strict;

sub content {
  my $self = shift;

  my $sd = $self->species_defs;

  return sprintf( qq(
  <div class="column-two left">
		  <p>
      %s release %d - %s
		  &copy; <span class="print_hide"><a href="http://www.ebi.ac.uk/" style="white-space:nowrap">EMBL-EBI</a></span>
      <span class="screen_hide_inline">EMBL-EBI</span>
      </p>
  </div>),     $sd->SITE_NAME, $sd->SITE_RELEASE_VERSION, $sd->SITE_RELEASE_DATE
	       );
}

1;

