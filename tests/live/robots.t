use strict;
use warnings;
use Test::More;
use Data::Dumper;

use lib 'lib';
use EG::Test::Utils qw(config);

my $ua = LWP::UserAgent->new(keep_alive => 5, env_proxy => 1);

test_robots_file();
test_sitemap_index();
done_testing();

sub test_robots_file {
  my $url = config->{url};
  my $response = $ua->get("$url/robots.txt");

  ok $response->is_success, 'fetched robots.txt';
  like $response->content, qr/Allow: \*\/Gene\/Summary/m , 'contains expected allow rule';
  like $response->content, qr/$url\/sitemap-index\.xml/m, 'contains url for sitemap index';
}

sub test_sitemap_index {
  my $url = config->{url};
  my $response = $ua->get("$url/sitemap-index.xml");
  
  ok $response->is_success, 'fetched sitemap index';
  like $response->content, qr/http:\/\/plants.ensembl.org\/sitemap_/m , 'contains at least on sitemap link';
}
