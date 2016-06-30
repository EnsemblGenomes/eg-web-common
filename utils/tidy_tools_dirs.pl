# Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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


# This script will remove files/dirs for jobs that were deleted in the 
# database but may still exist on disk. This is intended to be run in the 
# fallback environment where the disk may be out-of-sync with the db.

use strict;
use warnings;

use Cwd;
use File::Basename;
use File::Spec;
use Getopt::Long qw(GetOptions);

BEGIN {

  my @dirname   = File::Spec->splitdir(dirname(Cwd::realpath(__FILE__)));
  my $code_path = File::Spec->catdir(splice @dirname, 0, -2);

  # Load SiteDefs
  unshift @INC, File::Spec->catdir($code_path, qw(ensembl-webcode conf));
  eval {
    require SiteDefs;
  };
  if ($@) {
    print "ERROR: Can't use SiteDefs - $@\n";
    exit 1;
  }

  # Check if EnsEMBL::Tools exist in plugins
  if (!{@{$SiteDefs::ENSEMBL_PLUGINS}}->{'EnsEMBL::Tools'}) {
    print "ERROR: Tools plugin is not loaded. Please add it to the Plugins.pm file before running this script.\n";
    exit 1;
  }

  # Include all code dirs
  unshift @INC, reverse @{SiteDefs::ENSEMBL_LIB_DIRS};
  $ENV{'PERL5LIB'} = join ':', $ENV{'PERL5LIB'} || (), @INC;
}

use ORM::EnsEMBL::Rose::DbConnection;
use ORM::EnsEMBL::DB::Tools::Manager::Job;
use EnsEMBL::Web::SpeciesDefs;
use EnsEMBL::Web::Utils::FileSystem qw(remove_empty_path);

GetOptions(
  'dry'            => \(my $dry          = 0), 
  'hours=i'        => \(my $hours        = 1),
  'offset-hours=i' => \(my $offset_hours = 0),
  'v|verbose'      => \(my $verbose      = 0),
);

my $total_hours = $offset_hours + $hours;

print "INFO: Tidying jobs folders for jobs deleted in last $hours hours\n";
print "INFO: Time offset by $offset_hours hours\n" if $offset_hours;
print "INFO: This is a dry run\n" if $dry;

# Get db connection
my $sd  = EnsEMBL::Web::SpeciesDefs->new();
my $db  = {
  'database'  =>  $sd->multidb->{'DATABASE_WEB_TOOLS'}{'NAME'},
  'host'      =>  $sd->multidb->{'DATABASE_WEB_TOOLS'}{'HOST'},
  'port'      =>  $sd->multidb->{'DATABASE_WEB_TOOLS'}{'PORT'},
  'username'  =>  $sd->multidb->{'DATABASE_WEB_TOOLS'}{'USER'} || $sd->DATABASE_WRITE_USER,
  'password'  =>  $sd->multidb->{'DATABASE_WEB_TOOLS'}{'PASS'} || $sd->DATABASE_WRITE_PASS,
  'type'      => 'ticket',
  'domain'    => 'ensembl',
  'trackable' => 0
};

# Register db with rose api
ORM::EnsEMBL::Rose::DbConnection->register_database($db);

# Fetch all non-user tickets that are already marked as deleted
my $jobs_iterator = ORM::EnsEMBL::DB::Tools::Manager::Job->get_objects_iterator(
  'query'         => [ 
    'status'      => 'deleted',  
    'modified_at' => {'le_sql' => "NOW() - INTERVAL $offset_hours HOUR"},
    'modified_at' => {'ge_sql' => "NOW() - INTERVAL $total_hours HOUR"},
  ],
  'sort_by'       => 'modified_at ASC',
  'debug'         => 0,
);

# Any error?
if ($jobs_iterator->error) {
  print sprintf "ERROR: %s\n", $jobs_iterator->error;
  exit 1;
}

my %tools_list = @{ $SiteDefs::ENSEMBL_TOOLS_LIST };
my $errors     = 0;
my $deletions  = 0;

while (my $job = $jobs_iterator->next) {
  my @dir = File::Spec->splitdir($job->job_dir);
  my $dir = File::Spec->catdir(splice @dir, 0, -1);
  
  if (-d $dir) {
    print sprintf "INFO: Job %s - removing %s\n", $job->job_id, $dir;
    if (!$dry && !remove_empty_path($dir, { 'remove_contents' => 1, 'exclude' => [ keys %tools_list ], 'no_exception' => 1 })) {
      print "WARNING: Could not remove job directory $dir\n";
      $errors ++;
    } else {
      $deletions ++;
    }
  } elsif ($verbose) {
    print sprintf "INFO: Job %s - not found %s\n", $job->job_id, $dir;
  }
}

# Any error?
if ($jobs_iterator->error) {
  print sprintf "WARNING: %s\n", $jobs_iterator->error;
}

print sprintf "INFO: deleted jobs processed = %s\n", $jobs_iterator->total || 0;
print sprintf "INFO: job dirs deleted       = %s\n", $deletions;
print sprintf "INFO: deletion errors        = %s\n", $errors;
print "INFO: DONE\n";