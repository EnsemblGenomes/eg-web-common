#!/usr/local/bin/perl


use strict;
use warnings;

use Cwd;
use File::Basename;
use File::Spec;
use Getopt::Long qw(GetOptions);
use Data::Dumper;

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


  # Include all code dirs
  unshift @INC, reverse @{SiteDefs::ENSEMBL_LIB_DIRS};
  $ENV{'PERL5LIB'} = join ':', $ENV{'PERL5LIB'} || (), @INC;
}

use EnsEMBL::Web::SpeciesDefs;

my $sd  = EnsEMBL::Web::SpeciesDefs->new();

my $db  = {
  'database'  =>  $sd->multidb->{'DATABASE_WEB_TOOLS'}{'NAME'},
  'host'      =>  $sd->multidb->{'DATABASE_WEB_TOOLS'}{'HOST'},
  'port'      =>  $sd->multidb->{'DATABASE_WEB_TOOLS'}{'PORT'},
  'username'  =>  $sd->multidb->{'DATABASE_WEB_TOOLS'}{'USER'} || $sd->DATABASE_WRITE_USER,
  'password'  =>  $sd->multidb->{'DATABASE_WEB_TOOLS'}{'PASS'} || $sd->DATABASE_WRITE_PASS,
};


my $input = 'y';
while ($input !~ m/^(y|n)$/i) {
  print sprintf "\nThis will run queries on the following DB. Continue? %s\@%s:%s\nConfirm (y/n):", $db->{'database'}, $db->{'host'}, $db->{'port'};
  $input = <STDIN>;
}

close STDIN;

chomp $input;

die "Script aborted.\n" if $input =~ /n/i;


my $dbh = DBI->connect(sprintf('DBI:mysql:database=%s;host=%s;port=%s', $db->{'database'}, $db->{'host'}, $db->{'port'}), $db->{'username'}, $db->{'password'} || '')
  or die('Could not connect to the database');

# Create table if it doesn't exist
 get_total_blast_jobs($dbh);

####################################################################################

sub get_total_blast_jobs {
  my ($dbh) = @_;


  my $sth = $dbh->prepare("select count(*) from ticket where ticket_type_name = 'Blast'");
  $sth->execute;
  my $rows = $sth->fetchrow_array;

  printf "Total number of Blast jobs on this server are: %s\n", $rows;
}
