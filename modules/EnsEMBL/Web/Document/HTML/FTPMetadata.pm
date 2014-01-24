package EnsEMBL::Web::Document::HTML::FTPMetadata;

### This module outputs download links for genome metadata

use strict;
use warnings;

use EnsEMBL::Web::Hub;

use base qw(EnsEMBL::Web::Document::HTML);

sub render {
  my $self = shift;
  my $hub          = new EnsEMBL::Web::Hub;
  my $species_defs = $hub->species_defs;
  my $prefix       = 'ftp://ftp.ensemblgenomes.org/pub/release-' . $species_defs->SITE_RELEASE_VERSION;
  my $site         = $species_defs->ENSEMBL_SITETYPE;
  my $unit         = $species_defs->GENOMIC_UNIT;
  
  (my $division = $site) =~ s/\s//g;
  
  return qq{  
    <h2>Metadata</h2>
    <p>
      Detailed metadata on the genomes provided by Ensembl Genomes is available from the FTP site in TSV, JSON and XML formats 
      (<a href="ftp://ftp.ensemblgenomes.org/pub/README_metadata">format details</a>).
    </p>
    <p>
      $site:
      <a href="$prefix/$unit/species_$division.txt">TSV</a> |
      <a href="$prefix/$unit/species_metadata_$division.json">JSON</a> |
      <a href="$prefix/$unit/species_metadata_$division.xml">XML</a>
    </p>
    <p>
      Ensembl Genomes (all divisions):
      <a href="$prefix/species.txt">TSV</a> | 
      <a href="$prefix/species_metadata.json">JSON</a> | 
      <a href="$prefix/species_metadata.xml">XML</a>
    </p>
  };  
}



1;
