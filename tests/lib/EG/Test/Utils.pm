package EG::Test::Utils;
use strict;
use warnings;
use Getopt::Long;
use LWP::UserAgent;

use EG::Test::Selenium;

use parent qw(Exporter);
our @EXPORT_OK = qw( config selenium_from_config );

my $config;

# Build config from file or command line args (or both)
sub config {

  unless ($config) {
    
    # get defaults from config file
    my $file = $ENV{EG_TEST_CONFIG_FILE} || 'default.conf';
    if (-f $file) {
      $config = do ($file);
      die "Failed parsing config file '$file': expected HashRef" unless ref $config eq 'HASH';
    } else {
      warn "Cannot find config file '$file'"; 
    }

    # override with command line opts
    GetOptions $config, qw(
      species=s 
      url=s 
      selenium_host=s 
      selenium_port=i 
      selenium_browser=s 
      selenium_timeout=i
    );
  }

  return $config;
}

# Build a selenium object based on the config settings
sub selenium_from_config {
  
  my %args = (
    host        => config->{selenium_host},
    port        => config->{selenium_port},
    browser     => config->{selenium_browser},
    browser_url => config->{url},
    species     => config->{species},
    _timeout    => config->{selenium_timeout},
    _ua         => LWP::UserAgent->new(keep_alive => 5, env_proxy => 1),
  );

  return EG::Test::Selenium->new(%args);
}


1;