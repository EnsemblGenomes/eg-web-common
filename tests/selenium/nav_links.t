use strict;
use warnings;
use Test::More;

use lib 'lib';
use EG::Test::Utils qw(selenium_from_config);

my $sel = selenium_from_config;

my @entities = qw(region gene transcript variant);
my $js       = "\$('a', '.local_context').each(function(index) { \$(this).attr('id', 'nav_test_' + index); })"; # set ids;
  
foreach my $entity (@entities) {
  diag ucfirst($entity) . '...';
  
  $sel->eg_open_species_homepage,
  and $sel->eg_click_link("link=Example $entity");
  
  $sel->run_script($js);
  my @ids = $sel->get_all_links;
  
  foreach my $id (grep {/^nav_test_/} @ids) {
    $sel->run_script($js);
    my $href = $sel->get_eval("selenium.browserbot.getCurrentWindow().jQuery('a#$id').attr('href')");
    next unless $href =~ /^\//; # don't test external urls
    diag $href;
    $sel->eg_click_link_ok("id=$id");
  }
}

done_testing();
