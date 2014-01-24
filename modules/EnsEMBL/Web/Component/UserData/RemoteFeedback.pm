package EnsEMBL::Web::Component::UserData::RemoteFeedback;

sub content {
  my $self = shift;
  
  my $form = $self->new_form({'id' => 'url_feedback', 'method' => 'post'});

  $form->add_element(
      type => 'SubHeader',
      value => qq(Thank you - your remote data was successfully attached. Close this Control Panel to view your data),
    );
  $form->add_element( 'type' => 'ForceReload' );

  return $form->render;
}

1;
