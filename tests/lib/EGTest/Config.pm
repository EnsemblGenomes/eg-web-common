package EGTest::Config;
use strict;
use warnings;
use Getopt::Long;
use LWP::UserAgent;
use Data::Dumper;

my @OPTIONS = qw(
  config=s

  species=s 
  
  selenium_host=s 
  selenium_port=i 
  selenium_browser=s 
  selenium_timeout=i

  live_url=s
  live_data_db_host=s
  live_user_db_host=s 
);

# Parse the config from file and command line args
sub parse {
  my %args = @_;
  my $required = ref $args{required} eq 'ARRAY' ? $args{required} : [$args{required}];

  my $opts = {};
  GetOptions $opts, @OPTIONS;
  
  my $url         = $ARGV[0] || die "\nERROR: Please supply URL to test as the first argument\n\n";              
  my $config_file = delete $opts->{config};  
  my $default     = _load_config_file('_default');
  my $user        = $config_file ? _load_config_file($config_file) : {};

  # merge configs
  my $config = { %$default, %$user, %$opts, url => $url };

  # check for missing settings
  my @missing = _check_missing_keys($config, $required);
  die "\nERROR: Required config key(s) '" . join("', '", @missing) . "' not defined\n\n" if @missing; 

  return $config;
}

sub _check_missing_keys {
  my ($config, $required) = @_;
  my @missing;
  foreach my $prefix (@$required) {
    my @required_keys = map {s/=.$//r} grep {/^${prefix}/} @OPTIONS;
    foreach my $key (@required_keys) { 
      push @missing, $key unless defined $config->{$key};
    }
  }
  return @missing;
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
