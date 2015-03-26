#!/usr/local/bin/perl
use strict;
use warnings;

my ($filter_dc, $filter_node) = @ARGV;

my $nodes = {
  bacteria => {port => 8002, dcs => [qw(pg oy)], nodes => [68,69]},
  fungi    => {port => 8004, dcs => [qw(pg oy)], nodes => [60,61]},
  metazoa  => {port => 8001, dcs => [qw(pg oy)], nodes => [60,61]},
  plants   => {port => 8003, dcs => [qw(pg oy)], nodes => [60,61]},
  protists => {port => 8005, dcs => [qw(pg oy)], nodes => [60,61]}
};

foreach my $division (keys %$nodes) {
  my $port  = $nodes->{$division}->{port};
  my $dcs   = $nodes->{$division}->{dcs};
  my $nodes = $nodes->{$division}->{nodes};

  printf "\n" . uc($division) . "\n";
  
  foreach my $dc (grep {!$filter_dc || $_ eq $filter_dc} @$dcs) {
    foreach my $node (grep {!$filter_node || $_ eq $filter_node} @$nodes) {
      my $url = "http://ves-$dc-$node:$port";
      my $cmd = "prove tests/live/ :: --config $division $url --datacentre=$dc";
      print "$cmd\n";
      print `$cmd`;
    }
  } 
}