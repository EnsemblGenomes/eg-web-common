use 5.16.1;
use strict;
use warnings;
use Data::Dumper;
use FindBin qw($Bin);
use lib "$Bin/../../ensembl/modules";
use lib "$Bin/../../ensemblgenomes-api/modules";
use Bio::EnsEMBL::Utils::MetaData::DBSQL::GenomeInfoAdaptor;

my $gdba = Bio::EnsEMBL::Utils::MetaData::DBSQL::GenomeInfoAdaptor->build_adaptor();

my %genomes;

foreach (qw( Fungi Metazoa Plants Protists )) {
  $genomes{$_->species} = $_ for @{ $gdba->fetch_all_by_division("Ensembl$_") };
}

$genomes{$_->species} = $_ for @{ $gdba->fetch_all_with_peptide_compara };
$genomes{$_->species} = $_ for @{ $gdba->fetch_all_with_pan_compara };

my @sorted = sort {$a->division cmp $b->division || $a->species cmp $b->species} values %genomes;

say '[SPECIES_DISPLAY_NAME]';
say sprintf('%s = %s', $_->species, $_->name) for @sorted;

say "\n";

say '[ENSEMBL_SPECIES_SITE]';
say sprintf('%s = %s', $_->species, fudge_division($_->division)) for @sorted;


# Fudge to convert EnsemblBacteria -> bacteria 
sub fudge_division {
  my $division = shift;
  return 'ensembl' if $division eq 'Ensembl';
  return lc( $division =~ s/^Ensembl(.*)/$1/r ); 
}