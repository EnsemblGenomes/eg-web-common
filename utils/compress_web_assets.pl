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
use Getopt::Long;

my $plugin_dir;
my $out_file = 'web_assets.tar.gz';
my $verbose = 0;

GetOptions(
  "plugin-dir=s" => \$plugin_dir,
  "out-file=s"   => \$out_file,
  "v" => \$verbose,
) || die "Invalid options\n";

die "Please specify the plugin dir (example: --plugin_dir=eg-plugins/fungi)\n" if !$plugin_dir;
die "Plugin dir does not exist\n" if !-e $plugin_dir;
$plugin_dir =~ s/\/$//; # strip trailing slash

my @assets = qw(
  data
  htdocs/img
  htdocs/i
  htdocs/ssi
  htdocs/taxon_tree_data.js
);

my @optional_assets = qw(
  htdocs/registry.json
);

my @errors;
foreach (@assets) {
  push @errors, "Missing asset: $plugin_dir/$_" if !-e "$plugin_dir/$_";
}

die join "\n", @errors, "Aborted\n" if @errors;

foreach (@optional_assets) {
  push @assets, $_ if -e "$plugin_dir/$_";
}

if ($verbose) {
  print "Assets to compress:\n";
  print map {"$_\n"} @assets;
}

my $asset_str = join ' ', @assets; 
    
my $cmd = "tar -czv --exclude=CVS --directory $plugin_dir --file $out_file $asset_str";
print "$cmd\n";
`$cmd`;
