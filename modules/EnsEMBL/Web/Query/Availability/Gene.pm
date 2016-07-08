package EnsEMBL::Web::Query::Availability::Gene;

use strict;
use warnings;

use previous qw(_counts get);

## EG - add homoeologs
sub _counts {
  my $self = shift;
  my ($args, $member, $panmember) = @_;
  my $out = $self->PREV::_counts(@_);

  $out->{'homoeologs'} = $member->number_of_homoeologues if $member;   
  
  return $out;
}

## EG - add homoeologs
sub get {
  my $self = shift;
  my ($args) = @_;

  my $out       = $self->PREV::get(@_)->[0];
  my $member    = $self->compara_member($args);
  my $panmember = $self->pancompara_member($args);
  my $counts    = $self->_counts($args,$member,$panmember); # how to stop _counts being executed twice? once here, and once in PREV::get

  $out->{has_homoeologs} = $counts->{homoeologs};

  return [$out];
}

1;
