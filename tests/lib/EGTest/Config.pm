package EGTest::Config;
use strict;
use warnings;
use Config::Any::Perl;
use Getopt::Long;

# Valid config keys
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
  my %args         = @_;
  my $required     = ref $args{required} eq 'ARRAY' ? $args{required} : [$args{required}];
  my $config       = {};
  my $opts         = {};
  my @config_files = ('_default');

  # parse command line options
  GetOptions $opts, @OPTIONS;

  # get test url from argv
  my $url = $ARGV[0] || die "\nERROR: Please supply URL to test as the first argument\n\n"; 
  
  # check for user config file
  my $user_config = delete $opts->{config};
  push @config_files, $user_config if $user_config;              
  
  # load and merge config files
  $config = { %$config, %{ Config::Any::Perl->load("configs/$_.conf") } } for @config_files;

  # merge in the command line opts and url
  $config = { %$config, %$opts, url => $url };

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

1;
