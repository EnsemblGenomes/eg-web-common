package EG::Test::Config;
use strict;
use warnings;
use Getopt::Long;
use LWP::UserAgent;
use Data::Dumper;

# Parse the config from file and command line args
sub parse {
   
  my $opts        = _parse_commandline_opts();
  my $user_config = delete $opts->{config};
  my $url         = $ARGV[0];               

  warn "\n\nWarning: you have not specified a config file using the --config param\n\n" unless $user_config;
  die  "\n\nERROR: Please supply URL to test as the first argument\n\n" unless $url;  
  
  my $default     = _load_config_file('default');
  my $user        = $user_config ? _load_config_file($user_config) : {};

  # merge configs
  my $config = { %$default, %$user, %$opts, url => $url };
  
  return $config;
}

sub _parse_commandline_opts {
  my $opts = {};
  GetOptions $opts, qw(
    config=s
    
    species=s 
    division=s
    
    selenium_host=s 
    selenium_port=i 
    selenium_browser=s 
    selenium_timeout=i

    live_url=s
    live_data_db_host=s
    live_user_db_host=s 
  );
  return $opts;
}

sub _load_config_file {
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


1;