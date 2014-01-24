package EnsEMBL::Web::Component::Gene;

sub has_image {
    my $self = shift;
    $self->{'has_image'} = shift if @_;
    return $self->{'has_image'} || 0;
}

1;

