#!/usr/local/bin/perl

use strict;
use FindBin qw($Bin);
use Data::Dumper;
use DBI;
use Net::FTP;

BEGIN {
  unshift @INC, "$Bin/../../../conf";
  unshift @INC, "$Bin/../../../";
  require SiteDefs;
  unshift @INC, $_ for @SiteDefs::ENSEMBL_LIB_DIRS;
}

use LoadPlugins;
use EnsEMBL::Web::SpeciesDefs;
my $species_defs = EnsEMBL::Web::SpeciesDefs->new;

# get atlas species
my $ftp = Net::FTP->new('ftp.ebi.ac.uk');
$ftp->login("anonymous",'-anonymous@') or die "Cannot login ", $ftp->message;
my @files = $ftp->ls('/pub/databases/microarray/data/atlas/bioentity_properties/ensembl/');
$ftp->quit;


my %species_hash;
foreach (@files) {
  my $sp = shift [ split /\./, pop [ split /\//, $_ ] ]; # strip path and file ext
  $species_hash{$sp} = 1;
} 

my @species = keys %species_hash;

# discard species not configured in this ensembl instance
@species = grep { my $s = $_; grep { /^$s$/i } $species_defs->valid_species } @species;

# hack to get EG plugin name
(my $plugin = lc($SiteDefs::ENSEMBL_SITETYPE)) =~ s/^ensembl\s*//;

# crude check to see which ini files already have pride configured
my $grep = `grep "S4_EXPRESSION\\s*=\\s*1" $Bin/../../$plugin/conf/ini-files/*`;

print "\nIt looks like Expression Atlas is already configured in these ini files:\n";
print "$grep\n";

print "Species that should have Expression Atlas enabled:\n";
foreach (@species) {
  print sprintf "%-40s%s\n", $_, ($grep =~ /$_/mi ? 'ALREADY ENABLED' : "<-- NOT YET ENABLED"); 
}
print "\n";

