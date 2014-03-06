#!/usr/local/bin/perl                                                                                                                                                                                             
# Copyright [2009-2014] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;

package example_links_healthcheck;

### See additional options/documentation at end of script                                                                                                                                                         

use Carp;
use FindBin qw($Bin);
use File::Basename qw( dirname );
use Time::localtime;
use Time::HiRes qw(time);
use Getopt::Long;
use Pod::Usage;
use Data::Dumper qw( Dumper );
use Config::Tiny;
use File::Basename;
use Time::Local;
use LibDirs;

use Bio::EnsEMBL::DBLoader;
use EnsEMBL::Web::DBSQL::DBConnection;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::SeqIO;
use utils::Tool;

our $DUMPDIR;
our $file;
our $script_start_time = time();

&GetOptions(
  'dumpdir:s'       => \$DUMPDIR,
  'file:s'          => \$file,
);

my $release ||= $SiteDefs::ENSEMBL_VERSION;

my $SD     = EnsEMBL::Web::SpeciesDefs->new();
my $dbconn = EnsEMBL::Web::DBSQL::DBConnection->new(undef, $SD);

# get a list of valid species for this release                                                                                                                                                       

my $release_id  = $SD->ENSEMBL_VERSION;
my @release_spp = $SD->valid_species;


# Validate DUMPDIR                                                                                                                                                                                              
$DUMPDIR ||=  dirname("$Bin"). "/utils/release-$release/";
utils::Tool::check_dir($DUMPDIR);

$file ||= "meta_values_report.txt";
my $err_flag = 0;

open( IN, "> $DUMPDIR/$file" ) or die "Can't open infile $file: $!\n";
foreach my $spp (@release_spp) {

    ## CONNECT TO APPROPRIATE DATABASES                                                                                                                                                                       
    my $db;
    eval {
	my $databases = $dbconn->get_databases_species($spp, "core");
	$db =  $databases->{'core'} ||
	    die( "Could not retrieve core database for $spp" );
    };

    my $dbAdaptor      = $dbconn->get_DBAdaptor("core", $spp ) || ( utils::Tool::warning( 1, "$spp is not valid" ) && next );
    my $slice_adaptor   = $dbAdaptor->get_SliceAdaptor;
    my $gene_adaptor   = $dbAdaptor->get_GeneAdaptor;
    my $transcript_adaptor   = $dbAdaptor->get_TranscriptAdaptor;
    my $species_id     = $db->{'_species_id'};


    my $elems = [ 'location', 'gene', 'transcript' ];

    foreach my $elem (@$elems) {

         my ($param) = &query( $db,
          "SELECT meta_value                                                                                                                                                                                                FROM   meta                                                                                                                                                                                                      WHERE  meta_key = 'sample.".$elem."_param' and species_id = '$species_id'");
 
         my $count = &query( $db,
          "SELECT meta_value                                                                                                                                                                                     
           FROM   meta                                                                                                                                                                                           
           WHERE  meta_key = 'sample.".$elem."_param' and species_id = '$species_id'") || 0;

	 $param ||= '';
         my $slice = '';
                
         if ($elem eq 'location')  {
	   my ($chr, $coords) = split(':', $param);
	   $coords ||= '';
	   my ($start, $end)  = split('-', $coords);
	   eval {  $slice = $slice_adaptor->fetch_by_region( 'toplevel', $chr, $start, $end );  };
         }
         if ($elem eq 'gene') {
	   eval { $slice = $gene_adaptor->fetch_by_stable_id($param); };
         }
         if ($elem eq 'transcript') {
	   eval { $slice = $transcript_adaptor->fetch_by_stable_id($param); };
         }
         
         my $mod = 'Bio::EnsEMBL::Slice' if ($elem eq 'location');
         $mod = 'Bio::EnsEMBL::Gene' if ($elem eq 'gene');
         $mod = 'Bio::EnsEMBL::Transcript' if ($elem eq 'transcript');

	 if(!ref($slice) || !$slice->isa($mod)) {
	   if ((length($param) == 0) || ($param =~ /^(\s*)$/))   {
	     my $meta_key = $count ? ": 'sample.".$elem."_param'" : " - MISSING";
	     print IN "Missing $elem param:\n------------------\nDB: ".$db->{'_dbc'}->{'_dbname'} . "\nspecies_id: $species_id\nmeta key$meta_key\nmeta value - MISSING\n\n\n";
	   } else {
	     print IN "Invalid $elem param:\n------------------\nDB: ".$db->{'_dbc'}->{'_dbname'} . "\nspecies_id: $species_id\nmeta key: 'sample.gene_param'\nmeta value(INVALID): '$param'\n\n\n";
	   }
	   $err_flag++;
	 }
    }

    my ($search_text) = &query( $db,
          "SELECT meta_value
           FROM   meta
           WHERE  meta_key = 'sample.search_text' and species_id = '$species_id'");

    my $count_s = &query( $db,
          "SELECT meta_value                                                                                                                                                                                     
           FROM   meta                                                                                                                                                                                           
           WHERE  meta_key = 'sample.search_text' and species_id = '$species_id'") || 0;
  
    $search_text ||= '';
    if((length($search_text) == 0) || ($search_text =~ /^(\s*)$/)) {    
      my $meta_key = $count_s ? ": 'sample.search_param'" : " - MISSING";
      print IN "Missing SEARCH TEXT:\n------------------\nDB: ".$db->{'_dbc'}->{'_dbname'} . "\nspecies_id: $species_id\nmeta key$meta_key\nmeta value - MISSING\n\n\n";
      $err_flag++; 
    }
} 

print IN "NO MISSING/INVALID VALUES FOUND! " unless($err_flag);

close IN;


sub check_dir {
    my $dir = shift;
    if( ! -e $dir ){
      system("mkdir -p $dir") == 0 or
	( print("Cannot create $dir: $!" ) && next );
    }
    return;
}

sub query { my( $db, $SQL ) = @_;
	    my $sth = $db->dbc->prepare($SQL);
	    $sth->execute();
	    my @Q = $sth->fetchrow_array();
	    $sth->finish;
	    return @Q;
	}

1;


__END__
