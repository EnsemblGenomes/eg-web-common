use strict;
use warnings;
use Test::More;
use Data::Dumper;

use lib 'lib';
use EG::Test::Config qw(get_config);

my $config = get_config;
my $ua     = LWP::UserAgent->new(keep_alive => 5, env_proxy => 1);

test_status();
done_testing();

sub test_status {
  my $response = $ua->get("$config->{url}/Multi/status_report");
  
  ok $response->is_success, 'fetched status page';
  like $response->content, qr/STATUS: OK/m , 'status is ok';
  like $response->content, qr/USER_DB host is:\s+oy-mysql-eg-web/m , "user db is oy-mysql-eg-web";  

  if ($config->{datacentre}) {
    my $db = "$config->{datacentre}-mysql-eg-live";
    like $response->content, qr/DATA_DB host is:\s+$db/m , "data db is $db";  
  } else {
    note 'skipping datacentre db checks as no datacentre config supplied'
  }
}
