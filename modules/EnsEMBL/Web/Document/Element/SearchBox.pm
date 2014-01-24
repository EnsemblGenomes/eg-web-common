package EnsEMBL::Web::Document::Element::SearchBox;

### Generates small search box (used in top left corner of pages)

use strict;

sub search_options {
  my $sitename = $_[0]->species_defs->SITE_NAME;

  return [
    ($_[0]->hub->species and $_[0]->hub->species !~ /^(common|multi)$/i) ? (
    'ensemblthis'     => { 'label' => 'Search ' . $_[0]->species_defs->SPECIES_COMMON_NAME, 'icon' => 'search/ensembl.gif'  }) : (),
    'ensemblunit'     => { 'label' => "Search $sitename",       'icon' => 'search/ensemblunit.gif'      },
    'ensembl_genomes' => { 'label' => 'Search Ensembl genomes', 'icon' => 'search/ensembl_genomes.gif'  },
    'ensembl_all'     => { 'label' => 'Search all species',     'icon' => 'search/ensembl.gif'          },
    'ebi'             => { 'label' => 'Search EBI',             'icon' => 'search/ebi.gif'              },
  ];
}

1;


