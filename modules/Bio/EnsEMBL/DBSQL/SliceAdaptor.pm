package Bio::EnsEMBL::DBSQL::SliceAdaptor;
use strict;

sub _build_circular_slice_cache {
  my $self = shift;

  # build up a cache of circular sequence region ids
  my $sth =
    	$self->prepare( "SELECT sra.seq_region_id FROM seq_region_attrib sra "
		  	. "INNER JOIN attrib_type at ON sra.attrib_type_id = at.attrib_type_id "
			. "INNER JOIN seq_region sr ON sra.seq_region_id = sr.seq_region_id "
			. "INNER JOIN coord_system cs ON sr.coord_system_id = cs.coord_system_id "
			. "WHERE code = 'circular_seq' and cs.species_id = ?");

  $sth->bind_param( 1, $self->species_id(), SQL_INTEGER );
  $sth->execute();

  my $id;
  my %hash;
## EG - ENSEMBL-4580 - disable circular support outside of Bacteria site   
  if ($SiteDefs::ENSEMBL_SITETYPE =~ /bacteria/i and ($id) = $sth->fetchrow_array() ) {
##
  	$self->{'circular_sr_id_cache'} = \%hash;
        $self->{'is_circular'} = 1;
	$hash{ $id } = $id;
 	while ( ($id) = $sth->fetchrow_array() ) {
    		$hash{ $id } = $id;
  	}
  } else {
	$self->{'is_circular'} = 0;
  }
  $sth->finish();
} 

1;
