package EnsEMBL::Web::Component::Help::View;

sub content {
  my $self    = shift;
  my $hub     = $self->hub;
  my $adaptor = EnsEMBL::Web::DBSQL::WebsiteAdaptor->new($hub);
  foreach (@{$adaptor->fetch_help_by_ids([$hub->param('id')])}){
    my $content = $self->parse_help_html($_->{'content'}, $adaptor);
    $content =~ s/href="[.\/]*Homo_sapiens/href="http:\/\/www.ensembl.org\/Homo_sapiens/ig;
    $content =~ s/Scrolling over the inverted triangle/ Clicking on the inverted triangle/ig; 
    return $content;
  }
}

1;
