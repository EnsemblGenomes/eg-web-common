package EG::Test::Config;
use strict;
use warnings;

use parent qw(Exporter);
our @EXPORT_OK = qw( config );

sub config {
  state $config = do ($ENV{EG_TEST_CONFIG_FILE} or 'default.conf');
  return $config;
}
1;