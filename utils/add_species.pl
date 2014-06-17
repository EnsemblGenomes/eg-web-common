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

use DBI;
use strict;
use warnings;
use Config::Tiny;
use Data::Dumper;

############################################################################
# Script can be used for fungi and protists.
# To use for bacteria sample bacteria species needs to be added
# to %sample_species hash.
# Before running the script, check if $dir is correct.
#
# How to run:
# ./add_species.pl Trichoderma_reesei fungi eg-hx-staging-2 
###########################################################################


die "You should provide arguments: species_name and site. Ex: ./add_species.pl Trichoderma_reesei fungi eg-hx-staging-2"
        if (!$ARGV[0] || !$ARGV[1] || !$ARGV[2]);

my ($sp, $site, $server) = @ARGV;

# preconfigure this
my $dir = "/nfs/public/rw/ensembl/ensembl-genomes/release-22/$site";
my $dir = "/homes/jk/ensembl/branch_76";

# sample species used to copy over a config file and to add new species
# in the config files after these.
# bacteria and others should be added here.
my %sample_species = (
        fungi    => 'Aspergillus_fumigatus',
        protists => 'Giardia_lamblia',
        metazoa  => 'Daphnia_pulex',
        plants   => 'Oryza_meridionalis',
);

#ensembl-webcode/eg-web-ensembl-configs/
my $file=  -e $dir.'/ensembl-webcode/configs/'.$server.'/conf/ini-files/MULTI.ini' ?
        $dir.'/ensembl-webcode/configs/'.$server.'/conf/ini-files/MULTI.ini' :
        $dir.'/ebi-plugins/'.$server.'/conf/ini-files/MULTI.ini';

# cheking if database for a new species exists

my $conf = Config::Tiny->read($file);

my $dbh = DBI->connect('dbi:mysql:information_schema;host='
        .$conf->{DATABASE_WEBSITE}->{HOST}.';port='.$conf->{DATABASE_WEBSITE}->{PORT},
        $conf->{DATABASE_WEBSITE}->{USER}, $conf->{DATABASE_WEBSITE}->{PASS}, { 'RaiseError' => 1 } )
        or die "Can't connect to db host".$conf->{DATABASE_WEBSITE}->{HOST};

my $databases = $dbh->selectcol_arrayref('show databases');

my $core_db = lc($sp);
my @db = grep { $_ =~ /$core_db/ } @$databases;

if ($db[0]) {
        print "Database $db[0] exists","\n";
}
else {
        print "Database $db[0] doesn't exist","\n";
}

print "Checking if species.classification matches species.production_name\n";

$dbh->do("use $db[0]") or die $dbh->errstr;

$sp =~ m/(\w+)\_/;
my $short_name = substr($1,1);

my $query = qq{ select meta_key, meta_value from meta where
        (meta_key='species.classification' or meta_key='species.production_name')
        && meta_value like "%$short_name%"
};

my $array_ref = $dbh->selectall_arrayref($query);
map { print "$_->[0] => $_->[1]\n"; } @$array_ref;

$dbh->disconnect;

# copying a sample config file
my $new_species_config_name = "$dir/eg-web-$site/conf/ini-files/$sp.ini";
print "New species config name=".$new_species_config_name."\n";

if (-e $new_species_config_name){
        print "Config file for the species already exists: $new_species_config_name. Exiting. \n";
        exit;
}

# create a config file for species based on some example
my $sample_config = "$dir/eg-web-$site/conf/ini-files/".$sample_species{$site}.".ini";
print "Sample config file=".$sample_config;
`cp $sample_config $new_species_config_name`;

# check if ini file for new species has been created
unless (-e $new_species_config_name){
        print "Species ini file $new_species_config_name hasn't been created. Exiting.\n";
        exit;
}

# creating a config file for a new species
$conf = Config::Tiny->read($new_species_config_name);
$db[0] =~ /\_(\d+)$/;
warn "\nrelease verion=".$1;
my $species_release_version =  $1;

$conf->{general}->{SPECIES_RELEASE_VERSION} = $species_release_version;     # Change a value
$conf->{databases}->{DATABASE_USERDATA} = $core_db."_userdata";

delete $conf->{general}->{ONTOLOGY_SUBSETS};                        # Delete a value or section

# Saving config
$conf->write($new_species_config_name);

my $file2 =  -e $dir.'/ensembl-webcode/configs/eg-hx/conf/ini-files/DEFAULTS.ini' ?
        $dir.'/ensembl-webcode/configs/eg-hx/conf/ini-files/DEFAULTS.ini' :
        $dir.'/ebi-plugins/eg-hx/conf/ini-files/DEFAULTS.ini';

$conf = Config::Tiny->read($file2);

unless ($conf) {
        print "Can't get DB connect details from $file2\n";
        exit;
}

my $db_host = $conf->{DATABASE_USERDATA}->{HOST};
my $db_port = $conf->{DATABASE_USERDATA}->{PORT};
my $db_user = $conf->{DATABASE_USERDATA}->{USER};
my $db_pass = $conf->{DATABASE_USERDATA}->{PASS};
my $db_name = lc($sp)."_userdata";

warn "Userdata=".Dumper($conf->{DATABASE_USERDATA});
`mysqldump --single_transaction -d -h $db_host -P $db_port -u ensro zea_mays_userdata>/tmp/userdata.sql`;

# creating userdata database for a new species
$dbh = DBI->connect('dbi:mysql:information_schema;host='
        .$db_host.';port='.$db_port, $db_user, $db_pass, { 'RaiseError' => 1 } );
warn "CREATE DATABASE IF NOT EXIST $db_name";
$dbh->do("CREATE DATABASE IF NOT EXISTS $db_name");

$dbh->do("use $db_name") or die $dbh->errstr;
`mysql -h $db_host -P $db_port -u $db_user --password=$db_pass $db_name < /tmp/userdata.sql`; # add an error handler here

# check if tables exist
my $tables_exists = $dbh->selectcol_arrayref('show tables');

$dbh->disconnect;

unless (@$tables_exists) {
        print "Tables structure wasn't loaded into $db_name. Exiting\n";
}

`rm /tmp/userdata.sql`;

# add species alias and restart apache.
my $line_to_add = '    $SiteDefs::__species_aliases{'."'".$sp."'} = [qw($sp)];";

`sed -i '/$sample_species{$site}/a $line_to_add' $dir/eg-web-$site/conf/SiteDefs.pm`;

my $sample_sp_lowcase = lc($sample_species{$site});
`sed -i '/$sample_sp_lowcase = $site/a $core_db = $site' $dir/eg-web-common/conf/ini-files/DEFAULTS.ini`;

my $sp_name = $sp;
$sp_name =~ s/_/ /g;
my $sample_sp_nounderscore = $sample_species{$site};
$sample_sp_nounderscore =~ s/_/ /g;

`sed -i '/$sample_sp_lowcase = $sample_sp_nounderscore/a $core_db = $sp_name' $dir/eg-web-common/conf/ini-files/DEFAULTS.ini`;
#`ctrl_scripts/restart_server -r`;
print "Done. Now restart apache and check the species page.\n";

