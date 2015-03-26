package EG::Test::Config;
use strict;
use warnings;
use Getopt::Long;
use LWP::UserAgent;
use Data::Dumper;

use EG::Test::Selenium;

use parent qw(Exporter);
our @EXPORT_OK = qw( get_config selenium_from_config );

my $config;

# Build the config from file or command line args (or both)
sub get_config {

  unless ($config) {
    
    # get command line opts
    my $opts = {};
    GetOptions $opts, qw(
      config=s
      
      species=s 
      division=s
      datacentre=s
      
      selenium_host=s 
      selenium_port=i 
      selenium_browser=s 
      selenium_timeout=i
    );
    
    my $url = $ARGV[0] || die "\n\nERROR: Please supply URL to test as the first argument\n\n";
    $opts->{url} = $url;

    my $opt_config = delete $opts->{config};

    # load file configs
    my $default = _load_config('default');
    my $other   = $opt_config ? _load_config($opt_config) : {};

    # merge configs
    $config = { %$default, %$other, %$opts };

  }

  #warn "CONFIG " . Dumper $config;

  return $config;
}

sub _load_config {
  my $name = shift;
  my $file = "configs/$name.conf";
  my $config;

  if (-f $file) {
    $config = do ($file);
    die "Failed parsing config file '$file': expected HashRef" unless ref $config eq 'HASH';
  } else {
    die "Cannot find config file '$file'"; 
  }

  return $config;
}

# Build a selenium object based on the config settings
sub selenium_from_config {
  my $config = get_config();

  my %args = (
    host        => $config->{selenium_host},
    port        => $config->{selenium_port},
    browser     => $config->{selenium_browser},
    browser_url => $config->{url},
    species     => $config->{species},
    _timeout    => $config->{selenium_timeout},
    _ua         => LWP::UserAgent->new(keep_alive => 5, env_proxy => 1),
  );

  return EG::Test::Selenium->new(%args);
}

1;