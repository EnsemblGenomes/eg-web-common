#!/usr/bin/env perl

use strict;

use DBI;
use Data::Dumper;
$Data::Dumper::Indent   = 0;
$Data::Dumper::Maxdepth = 0;


my ($db_name, $db_host, $db_port, $db_user, $db_pass, %to_update);

$db_name = '';
$db_host = '';
$db_port = '';
$db_user = '';
$db_pass = '';

my %valid_divisions = ('metazoa' => 1, 'bacteria' => 1, 'plants' => 1, 'fungi' => 1, 'protists' => 1);

my $dsn = sprintf(
 'DBI:mysql:database=%s;host=%s;port=%s',
  $db_name,
  $db_host,
  $db_port,
);

my $dbh = DBI->connect(
  $dsn, $db_user, $db_pass
);


#$dbh->do('CREATE TABLE job_tmp LIKE job');
#$dbh->do('INSERT INTO job_tmp SELECT * FROM job');


my $sth = $dbh->prepare("SELECT job_id, job_dir FROM job where status = 'done'");
$sth->execute;


my $rows = []; # cache for batches of rows

while( my $row = ( shift(@$rows) || shift(@{$rows=$sth->fetchall_arrayref(undef,10_000)||[]}) )) {
  
  my ($job_id, $job_dir) = @$row;
  
  my @split_path = split 'ensembl-tmp-dirs', $job_dir;
  
  #We dont want to update paths for other divisions like parasite
  my @check_division = split '/', @split_path[1], 3;

  $to_update{$job_id} = '/nfs/incoming/ensweb/live'. @split_path[1] if exists $valid_divisions{$check_division[1]};
 
#  print $job_id . ":" . $to_update{$job_id} . "\n";

}




#warn Data::Dumper::Dumper(%to_update);

my $batchsize = 1000;
my $count = 0;

my $sth = $dbh->prepare('update job set job_dir = ? where job_id =?');

$dbh->begin_work;

while (my ($key, $value) = each (%to_update))
{
    $sth->execute($value, $key);
#    print "update job_copy set job_dir = '". $value . "' where job_id = '" . $key . "'\n";
 
    $count += 1;
    if ($count % $batchsize == 0)
    {
        $dbh->commit; 
        $dbh->begin_work;
    }
}


$dbh->commit;  


$dbh->disconnect;

