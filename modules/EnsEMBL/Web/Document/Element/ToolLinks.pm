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

package EnsEMBL::Web::Document::Element::ToolLinks;

use strict;
use warnings;

sub links {
  my $self  = shift;
  my $hub   = $self->hub;
  my $sd    = $self->species_defs;
  my $blog  = $sd->ENSEMBL_BLOG_URL;
  my @links;

  push @links, 'hmmer',         '<a class="constant" href="/hmmer">HMMER</a>' if $sd->ENSEMBL_HMMER_ENABLED;
  push @links, 'blast', sprintf '<a class="constant" href="%s">BLAST</a>', $hub->url({'species' => $hub->species || 'Multi', 'type' => 'Tools', 'action' => 'Blast', 'function' => ''}) if $sd->ENSEMBL_BLAST_ENABLED;
  push @links, 'biomart',       '<a class="constant" href="/biomart/martview">BioMart</a>';
  push @links, 'tools',         '<a class="constant" href="/tools.html">Tools</a>';
  push @links, 'downloads',     '<a class="constant" href="/info/data/ftp/index.html">Downloads</a>';
  push @links, 'docs',          '<a class="constant" href="/info/">Help &amp; Docs</a>';
  push @links, 'blog',          qq(<a class="constant" target="_blank" href="$blog">Blog</a>) if $blog;

  return \@links;
}


1;

