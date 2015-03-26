package EG::Test::Selenium;
use strict;
use base 'Test::WWW::Selenium';
use Test::More;

sub new {
  my ($class, %args) = @_;
  my $species = delete $args{species} || die 'Must provide species, e.g. Zea_mays';

  my $self = $class->SUPER::new(%args);
  $self->{species} = $species;

  $self->start;
  return $self;
}

# Wait until there are no ajax loading indicators or errors shown in the page
# Loading indicators are only shown if loading takes >500ms so need to pause before we start checking
sub eg_wait_for_ajax {
  my ($self, $timeout) = @_;
  $timeout ||= $self->{_timeout};

  $self->pause(500)
  and $self->wait_for_condition(
    'var $ = selenium.browserbot.getCurrentWindow().jQuery;
    !($(".ajax_load").length || $(".ajax_error").length || $(".syntax-error").length)',
    $timeout
  ); 
}

# Wait for a 200 Ok response, then wait until all ajax loaded
# For some reason the Ensembl 'Internal Server Error' page is mistaken for a 200 Ok, so also check for this
sub eg_wait_for_page_to_load {
  my ($self, $timeout) = @_;
  $timeout ||= $self->{_timeout};
  
  $self->wait_for_page_to_load($timeout)
  and $self->get_title !~ /Internal Server Error|404 error/i, 'No Internal or 404 Server Error'
  and $self->eg_wait_for_ajax($timeout);
}

sub eg_click_link {
  my ($self, $locator, $timeout) = @_;
  $timeout ||= $self->{_timeout};

  $self->click($locator)
  and $self->eg_wait_for_page_to_load($timeout);
}

sub eg_open_species_homepage {
  my ($self) = @_;
  $self->open("$self->{browser_url}/$self->{species}/Info/Index")
  and $self->eg_wait_for_page_to_load;
}

1;