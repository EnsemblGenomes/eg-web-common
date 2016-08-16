package EnsEMBL::Web::Query::Availability::Gene;

use strict;
use warnings;

use previous qw(_counts get);

## EG - add homoeologues
sub get {
  my $self = shift;
  my ($args) = @_;

  my $get       = $self->PREV::get(@_);
  my $member    = $self->compara_member($args) if $get->[0]->{'database:compara'};

  if ($member) {
    my $num_homoeologues = $member->number_of_homoeologues;
    $get->[0]->{counts}->{homoeologs} = $num_homoeologues;
    $get->[0]->{has_homoeologs}       = $num_homoeologues;
  }

  return $get;
}

1;
