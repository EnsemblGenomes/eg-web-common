use strict;
use warnings;
use Test::More;

use lib 'lib';
use EG::Test::Config;
use EG::Test::Selenium;

my $config = EG::Test::Config::parse(required => [qw(species selenium)]);
my $sel    = EG::Test::Selenium->new_from_config($config);

test_nav_links();
done_testing();

sub test_nav_links {
  my @entities = qw(region gene transcript variant);
  my $js       = "\$('a', '.local_context').each(function(index) { \$(this).attr('id', 'nav_test_' + index); })"; # set ids;
    
  foreach my $entity (@entities) {
    note ucfirst($entity) . '...';
    
    $sel->eg_open_species_homepage($config->{species}),
    and $sel->eg_click_link("link=Example $entity");
    
    $sel->run_script($js);
    my @ids = $sel->get_all_links;
    
    foreach my $id (grep {/^nav_test_/} @ids) {
      $sel->run_script($js);
      my $href = $sel->get_eval("selenium.browserbot.getCurrentWindow().jQuery('a#$id').attr('href')");
      next unless $href =~ /^\//; # don't test external urls
      note $href;
      $sel->eg_click_link_ok("id=$id");
    }
  }
}


