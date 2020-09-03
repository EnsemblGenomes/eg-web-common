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

#------------------------------------------------------------------------------
#
# Dump species taxonomy tree static files for EG taxon selector interface
#
# E.g. dump tree for all species in a site:
#
# perl ensembl-webcode/utils/dump_ensembl_valid_species.pl | 
#   perl eg-web-common/utils/dump_taxon_tree.pl --host <host> --port <port> 
#   --user <user> --pass <pass> --plugin-dir <dir> [--dump_binary] 
#   [--root <node-name>]
#
# E.g. dump tree for specific species:
#
# perl eg-web-common/utils/dump_taxon_tree.pl --host <host> --port <port> 
#   --user <user> --pass <pass> --plugin-dir <dir> [--dump_binary] 
#   [--root <node-name>] species1 species2 species3 ...
#
#------------------------------------------------------------------------------

use strict;
use Data::Dumper;
use FindBin qw($Bin);
use File::Path  qw(make_path);
use JSON;
use Storable qw(lock_nstore);
use Getopt::Long;
use lib $Bin;
use LibDirs;
use Bio::EnsEMBL::Registry;
use lib "$LibDirs::SERVERROOT/eg-web-bacteria/modules";

$| = 1; # disable buffering - helps when running on LSF
my $NO_CACHE = 1; # don't cache the registry

#use Bio::EnsEMBL::Registry; #Move it up to avoid loading Registry.pm inside eg-web-bacteria
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Taxonomy::DBSQL::TaxonomyNodeAdaptor;

my ($plugin_dir, $dump_binary, $division);
my ($host, $port, $user, $pass) = qw(localhost 3306 ensro);
my ($thost, $tport, $tuser, $tpass); # for ncbi_taxonomy
my $root_name = 'cellular organisms';

GetOptions(
  "host=s"       => \$host,
  "port=s"       => \$port,
  "user=s"       => \$user,
  "pass=s"       => \$pass,
  "thost=s"      => \$thost,
  "tport=s"      => \$tport,
  "tuser=s"      => \$tuser,
  "tpass=s"      => \$tpass,    
  "plugin-dir=s" => \$plugin_dir,
  "dump-binary"  => \$dump_binary,
  "root=s"       => \$root_name,
  "division=s"     => \$division
);

die "Please specifiy -plugin-dir" unless $plugin_dir;

if ($dump_binary) {
  # Dump EnsEMBL::Web::TaxonTree storable file (needed for Bacteria gene families)
  # Check we have EnsEMBL::Web::TaxonTree available before we start
  eval('use EnsEMBL::Web::TaxonTree'); 
  die "Could not load EnsEMBL::Web::TaxonTree, it is required for storable dump ($@)" if $@;
}

if ($division eq 'bacteria') {
  print "Loading script to lower the speed of generating new DB connection for Bacteria division\n";
  eval('use Bio::EnsEMBL::Taxonomy::DBSQL::TaxonomyNodeAdaptorDelay');
  die "Could not load Bio::EnsEMBL::Taxonomy::DBSQL::TaxonomyNodeAdaptorDelay, it is required to delay generating DB connections ($@)" if $@;
}

my @db_args = ( -host => $host, -port => $port, -user => $user, -pass => $pass );
my @ncbi_taxonomy_db_args = (@db_args);
if ( defined $thost && defined $tport ) {
    @ncbi_taxonomy_db_args = ( -host => $thost, -port => $tport, -user => $tuser || 'ensro', -pass => $tpass );
}

# try to get species from args or from a pipe
my @species_args = @ARGV;
if (!@species_args) {
  if (-t STDIN) { 
    print "This script expects a list of valid species, either as arguments or from a pipe\n";
    exit;
  } 
  while (<STDIN>) { # read from pipe
    chomp;
    push (@species_args, $_) if $_;
  }
}
die 'Need a list of species!' if !@species_args;
my %species = map {lc($_) => 1} @species_args; 

print "\nDumping taxon tree for " . scalar(keys %species) . " species...\n";

#------------------------------------------------------------------------------

# Per-division internal nodes 
# The tree will be collapsed to include only the internal nodes in the 
# custom_nodes hash. If empty, we'll get the default collapsed tree.

my $custom_node_config = {
  'Ensembl Plants' => { 
    4447   => 'Monocots',
    4479   => 'Grasses',
    147370 => 'Warm season grasses (C4)',
    147389 => 'Triticeae',
    4527   => 'Rices',
    71240  => 'Dicots',
    3700   => 'Brassicaceae',
    3803   => 'Fabaceae',
    4070   => 'Solanaceae',
  }
};

my $custom_nodes = $custom_node_config->{$SiteDefs::ENSEMBL_SITETYPE} || {};

#------------------------------------------------------------------------------

print "getting db adaptors...\n";

Bio::EnsEMBL::Registry->load_registry_from_db(@db_args);
#Bio::EnsEMBL::Registry->set_disconnect_when_inactive;

my @dbas  = grep { $species{$_->species} } @{ Bio::EnsEMBL::Registry->get_all_DBAdaptors(-group => 'core') };
#------------------------------------------------------------------------------

print "fetching leaf nodes...\n";

my $dba = Bio::EnsEMBL::DBSQL::DBAdaptor->new(
  @ncbi_taxonomy_db_args,
  -dbname => 'ncbi_taxonomy',
  -driver => 'mysql',
  -group  => 'taxonomy',
);

my $node_adaptor = Bio::EnsEMBL::Taxonomy::DBSQL::TaxonomyNodeAdaptor->new($dba);
my $root         = shift(@{$node_adaptor->fetch_all_by_name_and_class($root_name, 'scientific name')});
my $leaf_nodes   = $node_adaptor->fetch_by_coredbadaptors(\@dbas);

#------------------------------------------------------------------------------

print "building pruned tree...\n";

$node_adaptor->build_pruned_tree($root, $leaf_nodes);

print "collapsing tree...\n";

if (%$custom_nodes) {
  $node_adaptor->collapse_tree($root, sub {
    my ($node) = @_;
    return (
      $node->taxon_id eq $root->taxon_id ||
      (defined $node->dba && scalar(@{$node->dba}) > 0) ||
      grep {$_ eq $node->taxon_id} keys %$custom_nodes
    );
  });
} else {
  $node_adaptor->collapse_tree($root, sub { # change the collapse behaviour
    my ($node) = @_;
    return (
      $node->taxon_id() eq $root->taxon_id() ||
      ($node->dba() && scalar(@{$node->dba()}) > 0) ||
      scalar(@{$node->children()}) != 1 
      # ENSEMBL-3448 this line produces uncollapsed empty nodes 
      #|| scalar(@{$node->parent()->children()}) > 1   
    );
  }); 
}

#------------------------------------------------------------------------------

print "dumping JavaScript...\n"; 

my ($dynatree) = node_to_dynatree($root);
my $json       = to_json($dynatree->{children}, {pretty => 1, allow_nonref => 1});
my $filename   = "$plugin_dir/htdocs/taxon_tree_data.js";

open my $file, '>', $filename;
print $file "taxonTreeData = $json;";
close $file;
print "  wrote $filename\n";


if ($dump_binary) {
  print "dumping Perl storable file...\n";
  
  my $etree = EnsEMBL::Web::TaxonTree->new;
  $etree->append_child(node_to_ensembl($etree, $root));

  my $data_dir = "$plugin_dir/data";
  make_path($data_dir) unless -d $data_dir;
  
  my $filename = "$data_dir/taxon_tree.packed";
  lock_nstore($etree, $filename) or die("failed to write $filename ($@)");
  print "  wrote $filename\n";
}

exit;

#------------------------------------------------------------------------------
# Count number of dbas in a given (sub)tree

sub count_dbas {
  my ($tree, $sub) = @_;
  my $n = 0;
  $tree->traverse_tree(sub {
    my ($node, $depth) = @_;
    $n += scalar(@{$node->dba()});
    return;
  });
  return $n;
}

#------------------------------------------------------------------------------
# Dump JavaScript for the taxon tree interface

sub node_to_dynatree {
  my ($node) = @_;
  my $name        = $custom_nodes->{$node->taxon_id} || $node->names->{'scientific name'}->[0];
  my @child_nodes = @{$node->children};
  my @output;
  
  if (@child_nodes) {
    
    my $other;
    if ($node->is_root) {
      if (my @leaves = grep {$_->is_leaf} @child_nodes) {
        # move root leaf nodes into 'Other' 
        $other = {
          key      => 'Other',
          title    => 'Other' . ' (' . scalar(@leaves) . ')',
          children => [ map { node_to_dynatree($_) } @leaves ],
          isFolder => \"1" 
        };
        @child_nodes = grep {!$_->is_leaf} @child_nodes; # remove the leaves from root
      }
    }
    
    my @children = map { node_to_dynatree($_) } @child_nodes;
    push @children, $other if $other;
    
    push @output, {
      key      => $name,
      title    => $name . ' (' . count_dbas($node) . ')',
      children => [ sort {$a->{title} cmp $b->{title}} @children ],
      isFolder => \"1" 
    };
  }
  
  if (@{$node->dba}) {
    foreach my $dba (@{$node->dba}) {
      my $meta_adaptor = Bio::EnsEMBL::Registry->get_adaptor( $dba->species, "core", "MetaContainer" );
      my $display_name = $meta_adaptor->get_display_name();
      push @output, {  
        key   => ucfirst($dba->species),
        title => $display_name
      };
    }
  }  
  
  return @output;
}

#------------------------------------------------------------------------------
# Dump Ensembl tree object for gene families

sub node_to_ensembl {
  my ($etree, $node) = @_;
  my $name        = $custom_nodes->{$node->taxon_id} || $node->names->{'scientific name'}->[0];
  my @child_nodes = @{$node->children};
  my @output;
  
  if (@child_nodes) {
    
    my $other;
    if ($node->is_root) {
      if (my @leaves = grep {$_->is_leaf} @child_nodes) {
        # move root leaf nodes into 'Other' 
        my $other = $etree->create_node({
          id              => 'other_9000000',
          taxon_id        => 9000000,
          production_name => 'other',
          display_name    => 'Other',
          is_species      => 0
        });
        @child_nodes = grep {!$_->is_leaf} @child_nodes; # remove the leaves from root
      }
    }
    
    my @children = map { node_to_ensembl($etree, $_) } @child_nodes;
    push @children, $other if $other;
    
    my $enode = $etree->create_node({
      id              => $name . '_' . $node->taxon_id,
      taxon_id        => $node->taxon_id,
      production_name => $name,
      display_name    => $name,
      is_species      => 0
    });
    $enode->append_child($_) for ( sort {$a->display_name cmp $b->display_name} @children);
    push @output, $enode;
  }
  
  if (@{$node->dba}) {
    foreach my $dba (@{$node->dba}) {
      push @output, $etree->create_node({  
        id              => $dba->species . '_' . $node->taxon_id,
        taxon_id        => $node->taxon_id,
        production_name => $dba->species,
        display_name    => $name,
        is_species      => 1
      });
    }
  }
  
  return @output;
}


