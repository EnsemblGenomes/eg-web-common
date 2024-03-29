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
  my $lookup = $species_defs->prodnames_to_urls_lookup;
  my %species;

  foreach my $sp (@valid_species) {
    $species{$sp} = {
      'dir'           => $sp,
      'display_name'  => $species_defs->get_config($sp, 'SPECIES_DISPLAY_NAME'),
      'image'         => $species_defs->get_config($sp, 'SPECIES_IMAGE'),
      'assembly'      => $species_defs->get_config($sp, 'ASSEMBLY_NAME'),
      'accession'     => $species_defs->get_config($sp, 'ASSEMBLY_ACCESSION'),
      'taxon_id'      => $species_defs->get_config($sp, 'TAXONOMY_ID'),
      'group'         => $species_defs->get_config($sp, 'SPECIES_GROUP'),
      'variation'     => $species_defs->get_config($sp, 'databases')->{'DATABASE_VARIATION'},
      'regulation'    => $species_defs->get_config($sp, 'databases')->{'DATABASE_FUNCGEN'},
    };
  }

  # add meta data from Ensembl Genomes API (if available)
  my $mda = EnsEMBL::Web::DBSQL::MetaDataAdaptor->new($hub);
  if ($mda) {
    for my $genome (@{ $mda->all_genomes_by_division }) { 
      my $sp = $lookup->{$genome->name};
      if (!$species{$sp}) {
        warn "Warning: got meta data for genome '$sp' but this species is not configured. Skipping.";
        next; 
      }
      $species{$sp}->{genome_align} = $genome->has_genome_alignments;
      $species{$sp}->{other_align}  = $genome->has_other_alignments;
      $species{$sp}->{compara}      = $genome->has_peptide_compara;
      $species{$sp}->{pan_compara}  = $genome->has_pan_compara;    
    }
  } else {
    warn "Warning: it looks like the Meta Data database is unavailable";
  }

  my $html = '<style>#species-table td {vertical-align:middle;}</style><div class="js_panel" id="species-table">
      <input type="hidden" class="panel_type" value="Content">';

  my $columns = [
    { key => 'thumbnail',    title => '',                         width => '2%',  align => 'left', sort => 'none' },
    { key => 'display_name', title => 'Name',                     width => '47%', align => 'left', sort => 'string' },
    { key => 'group',        title => 'Classification',           width => '8%', align => 'left', sort => 'string' },
    { key => 'taxon_id',     title => 'Taxon ID',                 width => '8%', align => 'left', sort => 'integer' },
    { key => 'assembly',     title => 'Assembly',                 width => '8%', align => 'left' },
    { key => 'accession',    title => 'Accession',                width => '8%', align => 'left' },
    { key => 'variation',    title => 'Variation database',       width => '3%',  align => 'center', sort => 'string' },
    { key => 'regulation',   title => 'Regulation database',      width => '3%',  align => 'center', sort => 'string' },
    { key => 'genome_align', title => 'Whole genome alignments',  width => '3%',  align => 'center', sort => 'string' },
    { key => 'other_align',  title => 'Other alignments',         width => '3%',  align => 'center', sort => 'string' },
    { key => 'compara',      title => 'In peptide compara',       width => '3%',  align => 'center', sort => 'string' },
    { key => 'pan_compara',  title => 'In pan-taxonomic compara', width => '3%',  align => 'center', sort => 'string' },
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
  
  foreach my $info (sort {$a->{'display_name'} cmp $b->{'display_name'}} values %species) {
    next unless $info;
    my $dir           = $info->{'dir'};
    next unless $dir;
    my $display_name  = $info->{'display_name'};
    my $image         = $info->{'image'};
   
    my $thumbnail_html = qq(<a href="/$dir/" style="padding-right:4px;"><img src="/i/species/$image.png" width="48" height="48" title="$display_name" style="vertical-align:middle" /></a>);
    my $display_name_html = qq(<a href="/$dir" class="bigtext">$display_name</a>);
    my $tick_html      = '<img src="/i/tick_16.png" width="16" height="16" />';
    my $uniprot_link   = qq(<a href="http://www.uniprot.org/taxonomy/$info->{'taxon_id'}" target="_blank">$info->{'taxon_id'}</a>);
    my $ena_link       = $info->{'accession'} ? qq(<a href="http://www.ebi.ac.uk/ena/data/view/$info->{'accession'}" target="_blank">$info->{'accession'}</a>) : '-';

    $table->add_row({
      'thumbnail'     => $thumbnail_html,
      'display_name'  => $display_name_html,
      'group'         => $info->{'group'},
      'taxon_id'      => $uniprot_link,
      'assembly'      => $info->{'assembly'},
      'accession'     => $ena_link,
      'variation'     => $info->{'variation'}    ? $tick_html : '-',
      'regulation'    => $info->{'regulation'}   ? $tick_html : '-',
      'genome_align'  => $info->{'genome_align'} ? $tick_html : '-',
      'other_align'   => $info->{'other_align'}  ? $tick_html : '-',
      'compara'       => $info->{'compara'}      ? $tick_html : '-',
      'pan_compara'   => $info->{'pan_compara'}  ? $tick_html : '-',
    });
  }

  $html .= $table->render;
  $html .= '</div>';
  return $html;  
}

1;
