use strict;
use warnings;
use Test::More;
use Data::Dumper;

use lib 'lib';
use EG::Test::Config qw(get_config);

my $config   = get_config;
my $ua       = LWP::UserAgent->new(keep_alive => 5, env_proxy => 1);

test_robots_file();
test_sitemap_index();
done_testing();

sub test_robots_file {
  my $response = $ua->get("$config->{url}/robots.txt");
  
  ok $response->is_success, 'fetched robots.txt';
  like $response->content, qr/Allow: \*\/Gene\/Summary/m , 'contains example allow rule';
  like $response->content, qr/$config->{live_url}\/sitemap-index\.xml/m, 'contains url for sitemap index';
}

sub test_sitemap_index {
  my $response = $ua->get("$config->{url}/sitemap-index.xml");
  
  ok $response->is_success, 'fetched sitemap index';
  like $response->content, qr/$config->{live_url}\/sitemap_/m , 'contains at least one sitemap link';
}
