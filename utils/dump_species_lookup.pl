#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use FindBin qw($Bin);
use lib $Bin;
use LibDirs;
#use LoadPlugins;

use EnsEMBL::Web::DBHub; 
use EnsEMBL::Web::DBSQL::MetaDataAdaptor;

my $hub                 = EnsEMBL::Web::DBHub->new;
my $meta_data_adaptor   = EnsEMBL::Web::DBSQL::MetaDataAdaptor->new($hub);
my $genome_info_adaptor = $meta_data_adaptor->genome_info_adaptor;

my %genomes;

foreach my $division (qw( Ensembl EnsemblBacteria EnsemblFungi EnsemblMetazoa EnsemblPlants EnsemblProtists )) {
  $genomes{$_->species} = $_ for @{ $genome_info_adaptor->fetch_all_by_division($division) };
}

$genomes{$_->species} = $_ for @{ $genome_info_adaptor->fetch_all_with_compara };

my @sorted = sort {$a->division cmp $b->division || $a->species cmp $b->species} values %genomes;

# The ganome info db only has the Ensembl version of d.mel but we want an EnsemblMetazoa version 
# (i.e. Ensembl use common name 'Fruitfly', EG do not)
if (my $dmel = $genomes{'drosophila_melanogaster'}) {
  $dmel->name('Drosophila melanogaster');
  $dmel->division('EnsemblMetazoa');
}

print "[SPECIES_DISPLAY_NAME]\n";
printf("%s = %s\n", $_->species, $_->name) for @sorted;

print "\n";

print '[ENSEMBL_SPECIES_SITE]';
printf("%s = %s\n", $_->species, fudge_division($_->division)) for @sorted;


# Fudge to convert EnsemblBacteria -> bacteria etc.
sub fudge_division {
  my $division = shift;
  return 'ensembl' if $division eq 'Ensembl';
  return lc( $division =~ s/^Ensembl(.*)/$1/r ); 
}
