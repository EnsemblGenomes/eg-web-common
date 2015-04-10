use strict;
use warnings;
use Test::More;
use Data::Dumper;
use LWP::UserAgent;

use lib 'lib';
use EG::Test::Config;

my $config = EG::Test::Config::parse;
my $ua     = LWP::UserAgent->new(env_proxy => 1);

test_taxon_tree_data();
done_testing();

sub test_taxon_tree_data {
  my $response = $ua->get("$config->{url}/taxon_tree_data.js");

  ok $response->is_success, 'fetched taxon_tree_data.js';
  like $response->content, qr/taxonTreeData = \[/m , 'contains taxonTreeData array';
}
