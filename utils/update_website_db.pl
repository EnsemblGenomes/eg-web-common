#!/usr/bin/env perl
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

use File::Basename qw(dirname);
use Data::Dumper;
use FindBin qw($Bin);
use lib $Bin;
use LibDirs;
use EnsEMBL::Web::DBSQL::WebsiteAdaptor;
use EnsEMBL::Web::Hub;  

my $hub = new EnsEMBL::Web::Hub;
my $dbh = new EnsEMBL::Web::DBSQL::WebsiteAdaptor($hub)->db;
my $sd  = $hub->species_defs;
my $odb = $sd->multidb->{DATABASE_GO};

# Create help links for all ontology images ( just copy the master link for every ontology
if (my $odbh = DBI->connect( "dbi:mysql:$odb->{'NAME'};host=$odb->{'HOST'};port=$odb->{'PORT'}", $odb->{'USER'}, $odb->{'PASS'})) {

  # get the master help id
  my $sqlw = qq{select help_record_id from help_link where page_url = 'Transcript/Ontology/Image'};
   
  if (my @r = @{$dbh->selectall_arrayref($sqlw)||[]}) {

	  $dbh->do("DELETE FROM help_link WHERE page_url LIKE '%/Ontology/%' AND page_url NOT LIKE '%/Ontology/Image'");

	  if (my $hid = shift @{$r[0]}) {

	    my $sql = qq{
	      select ontology.namespace, ontology.name
        from ontology
        join term using (ontology_id)
        left join relation on (term_id=child_term_id)
        where relation_id is null
        group by ontology.ontology_id
        order by ontology.ontology_id
      };

	    my $sth = $odbh->prepare($sql);
	    $sth->execute;
	    my @ra = @{$sth->fetchall_arrayref || []};
	    
	    foreach my $r (@ra) {
    		$r->[0] =~ s/(-|\s)/_/g;
    		foreach my $url (qw( Transcript/Ontology Gene/Ontology )) {
    		  print "$url/$r->[0] = $hid\n";
    		  $dbh->do("INSERT INTO help_link SET page_url = ?, help_record_id = ?", undef, "$url/$r->[0]", $hid);    		
    		}
	    }
	    
	    $sth->finish;
	    $odbh->disconnect;
	  }
  }
}

$dbh->disconnect();
print "Done.\n";

exit;

#------------------------------------------------------------------------------

