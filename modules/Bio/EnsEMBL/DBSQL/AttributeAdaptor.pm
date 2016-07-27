package Bio::EnsEMBL::DBSQL::AttributeAdaptor;
use strict;

sub store_on_Slice {
  my ($self, $object, $attributes) = @_;

  assert_ref( $object, 'Bio::EnsEMBL::Slice');

  my $object_id = $object->get_seq_region_id();
  $self->store_on_Object($object_id, $attributes, 'seq_region');

  my $undef_circular_cache = 0;
  for my $attrib ( @$attributes ) {
## EG - ENSEMBL-4580 - disable circular support outside of Bacteria site   
    if ($SiteDefs::ENSEMBL_SITETYPE =~ /bacteria/i and (defined $attrib->code) and ($attrib->code eq 'circular_seq')) {
##
        $undef_circular_cache = 1;
    }
  }

  if ($undef_circular_cache) {
  #the slice is circular
    $object->{'circular'} = 1;
    my $slice_adaptor = $object->adaptor();
    #undefine slice adaptor->is_circular and the circular slice cache
    if (defined $slice_adaptor) {
      $slice_adaptor->{'is_circular'} = undef;
      $slice_adaptor->{'circular_sr_id_cache'} = {};
    }
  }

  return;
}

1;