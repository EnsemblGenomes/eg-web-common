use strict;
use warnings;
use Test::More;
use Data::Dumper;

use lib 'lib';
use EG::Test::Config;

my $config = EG::Test::Config::parse(required => 'live');
my $ua     = LWP::UserAgent->new(env_proxy => 1);

test_status();
done_testing();

sub test_status {
  my $response = $ua->get("$config->{url}/Multi/status_report");
  
  ok $response->is_success, 'fetched status page';
  like $response->content, qr/STATUS: OK/m , 'status is ok';

  if ($config->{live_data_db_host}) {
    like $response->content, qr/DATA_DB host is:\s+$config->{live_data_db_host}/m , "data db is correct";  
  } else {
    note 'skipping data db check as no config or live_data_db_host';
  }

  if ($config->{live_user_db_host}) {
    like $response->content, qr/USER_DB host is:\s+$config->{live_user_db_host}/m , "user db is correct";  
  } else {
    note 'skipping user db check as no config or live_user_db_host';
  }
}
