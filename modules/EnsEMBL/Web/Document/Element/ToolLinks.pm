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

package EnsEMBL::Web::Document::Element::ToolLinks;

### Generates links to site tools - BLAST, help, login, etc (currently in masthead)

use strict;

use previous qw(links);

use Data::Dumper;

sub links {
  my $self  = shift;
  my $links = $self->PREV::links(@_);

#  warn Dumper $links;

  $links = [];
  unshift @$links, 'docs', '<a class="constant" href="http://www.ensemblgenomes.org/info">Documentation</a>';

  unshift @$links, 'help', '<a class="constant" href="/info/website/index.html">Help</a>';

  unshift @$links, 'downloads',  '<a class="constant" href="/downloads.html">Downloads</a>';

  unshift @$links, 'tools',  '<a class="constant" href="/tools.html">Tools</a>';

  unshift @$links, 'biomart',  '<a class="constant" href="/biomart/martview">BioMart</a>';

  if ($self->hub->species_defs->ENSEMBL_BLAST_ENABLED) {
      unshift @$links, 'blast', sprintf '<a class="constant" href="%s">BLAST</a>', $self->hub->url({'species' => '', 'type' => 'Tools', 'action' => 'Blast'});
  }

  if ($self->hub->species_defs->ENSEMBL_ENASEARCH_ENABLED) {
      unshift @$links, 'seqsearch', sprintf '<a class="constant" href="%s">Sequence Search</a>', $self->hub->url({'species' => '', 'type' => 'Tools', 'action' => 'ENASearch'});
  }

  return $links;
}


1;

