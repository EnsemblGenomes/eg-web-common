=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Document::HTML::ToolsTable;

### Allows easy removal of items from template

use strict;

use EnsEMBL::Web::Document::Table;

use base qw(EnsEMBL::Web::Document::HTML);

sub render { 
  my $self        = shift;
  my $hub         = EnsEMBL::Web::Hub->new;
  my $sd          = $hub->species_defs;
  my $sp          = $sd->ENSEMBL_PRIMARY_SPECIES;
  my $img_url     = $sd->img_url;
  my $is_bacteria = $sd->GENOMIC_UNIT eq 'bacteria'; 
  my $url;

  my $table = EnsEMBL::Web::Document::Table->new([
      { key => 'name', title => 'Name', width => '20%', align => 'left' },
      { key => 'desc', title => 'Description', width => '50%', align => 'left' },
      { key => 'tool', title => 'Online tool', width => '10%', align => 'center' },
      { key => 'code', title => 'Download code', width => '10%', align => 'center' },
      { key => 'docs', title => 'Documentation', width => '10%', align => 'center' },
    ], [], { cellpadding => 4 }
  );

  ## VEP
  my $new_vep  = $sd->ENSEMBL_VEP_ENABLED;
  my $vep_link = $hub->url({'species' => $sp, $new_vep ? qw(type Tools action VEP) : qw(type UserData action UploadVariations)});
  $table->add_row({
    'name' => sprintf('<a href="%s" class="%snodeco"><b>Variant Effect Predictor</b><br /><img src="%svep_logo_sm.png" alt="[logo]" /></a>', $vep_link,  $new_vep ? '' : 'modal_link ', $img_url),
    'desc' => 'Analyse your own variants and predict the functional consequences of known and unknown variants via our Variant Effect Predictor (VEP) tool.',
    'tool' => sprintf('<a href="%s" class="%snodeco"><img src="%s16/tool.png" alt="Tool" title="Go to online tool" /></a>', $vep_link, $new_vep ? '' : 'modal_link ', $img_url),
    'code' => sprintf('<a href="https://github.com/Ensembl/ensembl-tools/archive/release/%s.zip" rel="external" class="nodeco"><img src="%s16/download.png" alt="Download" title="Download Perl script" /></a>', $sd->ENSEMBL_VERSION, $img_url),
    'docs' => '',
  });

  ## BLAST
  if ($sd->ENSEMBL_BLAST_ENABLED) {
    my $link = $hub->url({'species' => $sp, qw(type Tools action Blast)});
    $table->add_row({
      'name' => sprintf('<b><a class="nodeco" href="%s">BLAST/BLAT</a></b>', $link),
      'desc' => 'Search our genomes for your DNA or protein sequence.',
      'tool' => sprintf('<a href="%s" class="nodeco"><img src="%s16/tool.png" alt="Tool" title="Go to online tool" /></a>', $link, $img_url),
      'code' => '',
      'docs' => ''
    });
  }

  ## BIOMART
  if (!$is_bacteria) {
    $table->add_row({
      'name' => '<b><a class="nodeco" href="/biomart/martview">BioMart</a></b>',
      'desc' => 'Use this data-mining tool to export custom datasets from Ensembl.',
      'tool' => sprintf('<a href="/biomart/martview" class="nodeco"><img src="%s16/tool.png" alt="Tool" title="Go to online tool" /></a>', $img_url),
      'code' => sprintf('<a href="http://biomart.org" rel="external" class="nodeco"><img src="%s16/download.png" alt="Download" title="Download code from biomart.org" /></a>', $img_url),
      'docs' => sprintf('<a href="http://www.biomart.org/biomart/mview/help.html" class="popup"><img src="%s16/info.png" alt="Documentation" /></a>', $img_url)
    });
  }

  ## ASSEMBLY CONVERTER
  if (!$is_bacteria) {
    my $link = $hub->url({'species' => $sp, qw(type Tools action AssemblyConverter)});
    $table->add_row({
      'name' => sprintf('<b><a class="nodeco" href="%s">Assembly converter</a></b>', $link),
      'desc' => "Map (liftover) your data's coordinates to the current assembly.",
      'tool' => sprintf('<a href="%s" class="nodeco"><img src="%s16/tool.png" alt="Tool" title="Go to online tool" /></a>', $link, $img_url),
      'code' => '',
      'docs' => ''
    });
  }



  ## ID HISTORY CONVERTER
 
  my $tools_limit = '50MB';
  
  if ($sd->ENSEMBL_IDM_ENABLED) {
    my $link = $hub->url({'species' => $sp, qw(type Tools action IDMapper)});
    $table->add_row({
      'name'  => sprintf('<b><a class="nodeco" href="%s">ID History converter</a></b>', $link),
      'desc'  => 'Convert a set of Ensembl IDs from a previous release into their current equivalents.',
      'tool'  => sprintf('<a href="%s" class="nodeco"><img src="%s16/tool.png" alt="Tool" title="Go to online tool" /></a>', $link, $img_url),
      'limit' => $tools_limit,
      'code'  => sprintf('<a href="https://github.com/Ensembl/ensembl-tools/tree/release/%s/scripts/id_history_converter" rel="external" class="nodeco"><img src="%s16/download.png" alt="Download" title="Download Perl script" /></a>', $sd->ENSEMBL_VERSION, $img_url),
      'docs'  => '',
    });
  }

  ## VIRTUAL MACHINE
  $url = sprintf 'ftp://ftp.ensemblgenomes.org/pub/release-%s/virtual_machines', $SiteDefs::SITE_RELEASE_VERSION;
  $table->add_row({
    'name' => sprintf('<b><a class="nodeco" href="%s">Ensembl Genomes Virtual Machine</a></b>', $url),
    'desc' => 'Pre-configured VirtualBox virtual machine (VM) running the latest Ensembl Genomes browser.',
    'tool' => '',
    'code' => sprintf('<a href="%s" rel="external" class="nodeco"><img src="%s16/download.png" alt="Download" title="Download Virtual Machine" /></a>', $url, $img_url),
    'docs' => sprintf('<a href="http://ensemblgenomes.org/info/access/virtual_machine"><img src="%s16/info.png" alt="Documentation" /></a>', $img_url)
  });
  
  ## REST
  if (my $rest_url = $sd->ENSEMBL_REST_URL) {
    $table->add_row({
      "name" => sprintf("<b><a href=%s>Ensembl Genomes REST server</a></b>", $rest_url),
      'desc' => 'Access Ensembl data using your favourite programming language',
      "tool" => sprintf("<a href='%s' class='nodeco'><img src='%s16/tool.png' alt='Tool' title='Go to online tool' /></a>", $rest_url, $img_url),
      'code' => sprintf('<a href="https://github.com/EnsemblGenomes/eg-rest" rel="external" class="nodeco"><img src="%s16/download.png" alt="Download" title="Download source code" /></a>', $img_url),
      'docs' => sprintf('<a href="%s"><img src="%s16/info.png" alt="Documentation" /></a>', $sd->ENSEMBL_REST_DOC_URL || $rest_url, $img_url)
    });
  }

  return $table->render;
}

1;
