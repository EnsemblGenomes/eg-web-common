=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Document::HTML::SpeciesPage;

### Renders the content of the  "Find a species page" linked to from the SpeciesList module

use strict;
use EnsEMBL::Web::Document::Table;
use EnsEMBL::Web::DBSQL::MetaDataAdaptor;
use base qw(EnsEMBL::Web::Document::HTML);

sub render {
  my ($self, $request) = @_;

  my $hub           = $self->hub;
  my $species_defs  = $hub->species_defs;
  my $version       = $species_defs->ENSEMBL_VERSION;
  my $sitename      = $species_defs->ENSEMBL_SITETYPE;
  my $static_server = $species_defs->ENSEMBL_STATIC_SERVER;
  my @valid_species = $species_defs->valid_species;
  my %species;

  foreach my $sp (@valid_species) {
    $species{$sp} = {
      'dir'        => $sp,
      'common'     => $species_defs->get_config($sp, 'SPECIES_COMMON_NAME'),
      'assembly'   => $species_defs->get_config($sp, 'ASSEMBLY_NAME'),
      'accession'  => $species_defs->get_config($sp, 'ASSEMBLY_ACCESSION'),
      'taxon_id'   => $species_defs->get_config($sp, 'TAXONOMY_ID'),
      'variation'  => $species_defs->get_config($sp, 'databases')->{'DATABASE_VARIATION'},
      'regulation' => $species_defs->get_config($sp, 'databases')->{'DATABASE_FUNCGEN'},
    };
  }

  # add meta data from Ensembl Genomes API (if available)
  my $genome_info_adaptor = EnsEMBL::Web::DBSQL::MetaDataAdaptor->new($hub);
  if ($genome_info_adaptor) {
    for my $genome (@{ $genome_info_adaptor->all_genomes_by_division }) {
      my $sp = ucfirst $genome->species;
      my $sp_hash = $species{$sp};
      if (!$sp_hash) {
        warn "Warning: got meta data for genome '$sp' but this species is not configured. Skipping.";
        next; 
      }
      $sp_hash = {%$sp_hash,
        genome_align => $genome->has_genome_alignments,
        other_align  => $genome->has_other_alignments,
        pan_compara  => $genome->has_pan_compara,       
      };
    }
  } else {
    warn "Warning: it looks like the Meta Data database is unavailable";
  }

  my $html = '<div class="js_panel" id="species-table">
      <input type="hidden" class="panel_type" value="Content">';

  my $columns = [
    { key => 'common',       title => 'Common name',              width => '45%', align => 'left', sort => 'string' },
    { key => 'taxon_id',     title => 'Taxon ID',                 width => '10%', align => 'left', sort => 'integer' },
    { key => 'assembly',     title => 'Assembly',                 width => '10%', align => 'left' },
    { key => 'accession',    title => 'Accession',                width => '10%', align => 'left' },
    { key => 'variation',    title => 'Variation database',       width => '5%',  align => 'center', sort => 'string' },
    { key => 'regulation',   title => 'Regulation database',      width => '5%',  align => 'center', sort => 'string' },
    { key => 'genome_align', title => 'Whole genome alignments',  width => '5%',  align => 'center', sort => 'string' },
    { key => 'other_align',  title => 'Other alignments',         width => '5%',  align => 'center', sort => 'string' },
    { key => 'pan_compara',  title => 'In pan-taxonomic compara', width => '5%',  align => 'center', sort => 'string' },
  ];

  my $table = EnsEMBL::Web::Document::Table->new($columns, [], { 
    data_table => 1, 
    exportable => 1,
    data_table_config => {
      oSearch =>  { sSearch => $hub->param('search') || '' }
    }
  });
  $table->code     = 'species_index';
  $table->filename = 'Species';
  
  foreach my $info (sort {$a->{'common'} cmp $b->{'common'}} values %species) {
    next unless $info;
    my $dir       = $info->{'dir'};
    next unless $dir;
    my $common    = $info->{'common'};
   
    my $common_html = sprintf(
      '<a href="/%s/" style="float:left;padding-right:4px;"><img src="/i/species/48/%s.png" width="48" heeght="48" title="%s" /></a>
       <a href="/%s" class="bigtext">%s</a>',
      $dir, $dir, $common, $dir, $common
    );

    $table->add_row({
      'common'       => $common_html,
      'taxon_id'     => $info->{'taxon_id'},
      'assembly'     => $info->{'assembly'},
      'accession'    => $info->{'accession'} || '-',
      'variation'    => $info->{'variation'}    ? 'Y' : '-',
      'regulation'   => $info->{'regulation'}   ? 'Y' : '-',
      'genome_align' => $info->{'genome_align'} ? 'Y' : '-',
      'other_align'  => $info->{'other_align'}  ? 'Y' : '-',
      'pan_compara'  => $info->{'pan_compara'}  ? 'Y' : '-',
    });
  }

  $html .= $table->render;
  $html .= '</div>';
  return $html;  
}

1;
