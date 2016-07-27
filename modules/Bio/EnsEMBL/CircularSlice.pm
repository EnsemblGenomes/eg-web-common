package Bio::EnsEMBL::CircularSlice;
use strict;

sub is_circular {
  my ($self) = @_;

  if ( !defined( $self->{'circular'} ) ) {
    my @attrs =
      grep { $_ } @{ $self->get_all_Attributes('circular_seq') };
## EG - ENSEMBL-4580 - disable circular support outside of Bacteria site   
    $self->{'circular'} = ($SiteDefs::ENSEMBL_SITETYPE =~ /bacteria/i and @attrs) ? 1 : 0;
##
  }

  return $self->{'circular'};
}

1;