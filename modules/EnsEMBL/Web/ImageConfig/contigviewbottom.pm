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

# $Id: contigviewbottom.pm,v 1.7 2013-11-27 14:23:52 ek3 Exp $

package EnsEMBL::Web::ImageConfig::contigviewbottom;

use strict;
use warnings;

use previous qw(initialize);

sub modify {
  my $self = shift;
  
  $self->load_configured_bam;
  $self->load_configured_bed;
  $self->load_configured_bedgraph;
  $self->load_configured_mw;

  my $ml = $self->get_node('fg_methylation_legend');
  $ml->remove if $ml;
} 

sub initialize {
  ## @plugin
  ## Adds blast track to the config
  my $self = shift;
  $self->PREV::initialize(@_);

  ## replace "BLAST/BLAST" with "BLAST"

  if (my $node = $self->get_node('blast')) {
    $node->set('caption', 'BLAST hits');
    $node->set('name', 'BLAST hits');
    $node->set('description', 'Track displaying BLAST hits for the selected job');
  }

  if (my $node = $self->get_node('blast_legend')) {
    $node->set('caption', 'BLAST Legend');
    $node->set('name', 'BLAST Legend');
  }
}

sub modify {
  my $self = shift;

  my $gene_transcript_menu = $self->tree->get_node('gene_transcript');
   
  # create pombase menus
  my $pombase_menu_binding = $self->create_submenu('chromatin_binding', 'Chromatin binding');
  $gene_transcript_menu->after($pombase_menu_binding);

  my $pombase_menu_intron = $self->create_submenu('pb_intron_branch_point', 'Intron Branch Point');
  $gene_transcript_menu->after($pombase_menu_intron);

  my $pombase_menu_polya   = $self->create_submenu('polya_sites', 'Polyadenylation sites');
  $gene_transcript_menu->after($pombase_menu_polya);

  my $pombase_menu_reppro   = $self->create_submenu('replication_profiling', 'Replication Profiling');
  $gene_transcript_menu->after($pombase_menu_reppro);

  my $pombase_menu_reppro   = $self->create_submenu('regulatory_elements', 'Regulatory Elements');
  $gene_transcript_menu->after($pombase_menu_reppro);

  my $pombase_menu_transcriptome   = $self->create_submenu('transcriptome', 'Transcriptome');
  $gene_transcript_menu->after($pombase_menu_transcriptome);

  my $pombase_menu_nucleosome   = $self->create_submenu('nucleosome', 'Nucleosome Positioning');
  $gene_transcript_menu->after($pombase_menu_nucleosome);

  my $dnameth_menu_transcriptome   = $self->create_submenu('dna_methylation', 'DNA Methylation');
  $gene_transcript_menu->after($dnameth_menu_transcriptome);
 
  my $histmod_menu_transcriptome   = $self->create_submenu('histone_mod', 'Histone Modification');
  $gene_transcript_menu->after($histmod_menu_transcriptome);
  
  $self->load_configured_bam;
  $self->load_configured_bed;
  $self->load_configured_bedgraph;
  $self->load_configured_mw;

  my $ml = $self->get_node('fg_methylation_legend');
  $ml->remove if $ml; 
} 

1;
