#!/usr/bin/env perl
# Copyright [2009-2022] EMBL-European Bioinformatics Institute
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
use DBI;
use Data::Dumper;
use Getopt::Long;

my ($uhost, $uport, $uuser, $upass); # userdata
my ($chost, $cport, $cuser, $cpass); # core

GetOptions(
  "uhost=s" => \$uhost, "uport=s" => \$uport, "uuser=s" => \$uuser, "upass=s" => \$upass,
  "chost=s" => \$chost, "cport=s" => \$cport, "cuser=s" => \$cuser, "cpass=s" => \$cpass,
) || die "Invalid options\n";

die "Please supply userdata mysql credentials: --uhost --uport --uuser [--upass]\n" if !(defined $uhost and defined $uport and defined $uuser);
die "Please supply core mysql credentials: --chost --cport --cuser [--cpass]\n"     if !(defined $chost and defined $cport and defined $cuser);

# global db handles

my $udbh = DBI->connect("DBI:mysql:database=test;host=$uhost;port=$uport", $uuser, $upass);
my $cdbh = DBI->connect("DBI:mysql:database=test;host=$chost;port=$cport", $cuser, $cpass);

my $species_db;

# get userdata dbs

my $udbs = $udbh->selectcol_arrayref("show databases like '%_userdata'");

foreach (@$udbs) {
  next if /_collection_/;
  my ($species) = split /_userdata/;
  $species_db->{$species}->{userdata} = $_ ;
} 

# get core dbs

my $cdbs = $cdbh->selectcol_arrayref("show databases like '%_core_%'");

foreach (@$cdbs) {
  next if /_collection_/;
  my ($species) = split /_core_/;
  $species_db->{$species}->{core} = $_ ;
} 

print "Checking for missing userdata dbs...\n";

my @missing = sort grep { ! exists $species_db->{$_}->{userdata} } keys %$species_db;

if (@missing) {
  print "Creating missing userdata dbs...\n";
  
  my $core_db = $species_db->{$missing[0]}->{'core'};
  `mysqldump --no-data --lock-tables=false -h $chost -P $cport -u $cuser $core_db > /tmp/core_schema.sql`;
  
  foreach my $species (@missing) {
    create_userdata_db($species_db->{$species}->{core});
    $species_db->{$species}->{userdata} = "${species}_userdata";
  }
}

print "Checking for changed assemblies...\n";

foreach my $species (sort keys %$species_db) { 
  if (!$species_db->{$species}->{core}) {
    print "ORPHANED - userdata db $species doesn't have matching core db\n";
    next;
  }
  
  #print "DB $species\n";
  my $core_db     = $species_db->{$species}->{core};
  my $userdata_db = $species_db->{$species}->{userdata};
  
  $cdbh->do("USE $core_db");
  $udbh->do("USE $userdata_db");

  my $species_ids = $udbh->selectcol_arrayref('SELECT DISTINCT species_id FROM meta WHERE species_id IS NOT NULL');
  
  foreach my $species_id (@$species_ids) {
    my $sql = 'SELECT meta_value FROM meta WHERE species_id = ? AND meta_key = "assembly.name"';
    my $old_assembly =  $udbh->selectrow_array($sql, undef, $species_id);
    my $new_assembly =  $cdbh->selectrow_array($sql, undef, $species_id);
    if ($old_assembly ne $new_assembly) {
      print "ASSEMBLY MISMATCH - $species, old: '$old_assembly', new: '$new_assembly'\n" ;
      #upgrade_assembly($species_id, $core_db, $userdata_db);
    }
  }
}

$udbh->disconnect;
$cdbh->disconnect;

#------------------------------------------------------------------------------

sub create_userdata_db {
  my ($core_db) = @_;
  return unless $core_db;
  my ($species, $rest ) = split /_core_/, $core_db;
  my $user_db = $species ."_userdata";

  warn "CREATING $user_db \n";
  `mysqldump --single_transaction -h $chost -P $cport -u $cuser $core_db analysis meta meta_coord coord_system seq_region > /tmp/${user_db}.sql`;

  # creating userdata database for a new species
  $udbh->do("CREATE DATABASE IF NOT EXISTS $user_db");
  $udbh->do("use $user_db") or die $udbh->errstr;
  `mysql -h $uhost -P $uport -u $uuser --password=$upass $user_db < /tmp/core_schema.sql`; # add an error handler here
  `mysql -h $uhost -P $uport -u $uuser --password=$upass $user_db < /tmp/${user_db}.sql`;  # add an error handler here

  # check if tables exist
  my $tables_exist = $udbh->selectcol_arrayref('show tables');
  warn "ERROR: Table structure wasn't loaded into $user_db\n" if !@$tables_exist
  #`rm /tmp/{$user_db}.sql`;
}

#sub upgrade_assembly {
#  my ($species_id, $core_db, $userdata_db) = @_;
#}


