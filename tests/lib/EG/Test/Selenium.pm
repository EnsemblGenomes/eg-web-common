package EG::Test::Selenium;
use strict;
use base 'Test::WWW::Selenium';
use Test::More;

# return user defined timeout, or a default
sub _timeout {  return $_[0]->{_timeout} || 3000 }

# Wait until there are no ajax loading indicators or errors shown in the page
# Loading indicators are only shown if loading takes >500ms so need to pause before we start checking
sub ensembl_wait_for_ajax {
  my ($self, $timeout) = @_;
    
  $self->pause(500)
  and $self->wait_for_condition(
    'var $ = selenium.browserbot.getCurrentWindow().jQuery;
    !($(".ajax_load").length || $(".ajax_error").length || $(".syntax-error").length)',
    $timeout || $self->_timeout
  ); 
}

# Wait for a 200 Ok response, then wait until all ajax loaded
# For some reason the Ensembl 'Internal Server Error' page is mistaken for a 200 Ok, so also check for this
sub ensembl_wait_for_page_to_load {
  my ($self, $timeout) = @_;
  
  $timeout ||= $self->_timeout;
  
  $self->wait_for_page_to_load($timeout);
  ok($self->get_title !~ /Internal Server Error|404 error/i, 'No Internal or 404 Server Error');
  $self->ensembl_wait_for_ajax($timeout);
}

1;