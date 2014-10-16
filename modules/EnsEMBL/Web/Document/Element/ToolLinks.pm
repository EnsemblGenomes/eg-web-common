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

use strict;

sub links {
  my $self  = shift;
  my $hub   = $self->hub;
  my $sd    = $self->species_defs;
  my @links;

  push @links, 'blast', sprintf '<a class="constant" href="%s">BLAST</a>', $self->hub->url({'species' => '', 'type' => 'Tools', 'action' => 'Blast'}) if $sd->ENSEMBL_BLAST_ENABLED;
  push @links, 'ena',           '<a class="constant" href="/Multi/enasearch">Sequence Search</a>' if $sd->ENSEMBL_ENASEARCH_ENABLED;
  push @links, 'mart',          '<a class="constant" href="/biomart/martview">BioMart</a>' if $sd->ENSEMBL_MART_ENABLED;
  push @links, 'tools',         '<a class="constant" href="/info/docs/tools/index.html">Tools</a>';
  push @links, 'download',      '<a class="constant" href="/downloads.html">Downloads</a>';
  push @links, 'help',          '<a class="constant" href="/info/website/index.html">Help</a>';
  push @links, 'documentation', '<a class="constant" href="http://www.ensemblgenomes.org/info">Documentation</a>';
  push @links, 'mirrors',       '<a class="constant modal_link" href="/Help/Mirrors">Mirrors</a>' if keys %{$sd->ENSEMBL_MIRRORS || {}};

  return \@links;
}

1;

