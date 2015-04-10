#!/usr/local/bin/perl
use strict;
use warnings;
use Getopt::Long;

my $v = '';
GetOptions('v' => \$v);
$v = '-v' if $v;

my ($filter_dc, $filter_node) = @ARGV;

my $nodes = {
  bacteria => {port => 8002, dcs => [qw(pg oy)], nodes => [68,69]},
  fungi    => {port => 8004, dcs => [qw(pg oy)], nodes => [60,61]},
  metazoa  => {port => 8001, dcs => [qw(pg oy)], nodes => [60,61]},
  plants   => {port => 8003, dcs => [qw(pg oy)], nodes => [60,61]},
  protists => {port => 8005, dcs => [qw(pg oy)], nodes => [60,61]}
};

my $dbs = {
  pg => {data => 'pg-mysql-eg-live', user => 'oy-mysql-eg-web'},
  oy => {data => 'oy-mysql-eg-live', user => 'oy-mysql-eg-web'},
};

foreach my $division (keys %$nodes) {
  my $port  = $nodes->{$division}->{port};
  my $dcs   = $nodes->{$division}->{dcs};
  my $nodes = $nodes->{$division}->{nodes};

  printf "\n" . uc($division) . "\n";
  
  foreach my $dc (grep {!$filter_dc || $_ eq $filter_dc} @$dcs) {
    foreach my $node (grep {!$filter_node || $_ eq $filter_node} @$nodes) {
      
      my $cmd = "prove $v tests/multi_live/ :: http://ves-$dc-$node:$port --config $division --live_data_db_host=$dbs->{$dc}->{data} --live_user_db_host=$dbs->{$dc}->{user}";
      print "$cmd\n";
      print `$cmd`;
    
    }
  } 
}
