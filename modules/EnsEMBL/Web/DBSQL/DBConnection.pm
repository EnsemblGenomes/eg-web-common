package EnsEMBL::Web::DBSQL::DBConnection;


sub get_databases_species {
  my $self = shift;
  my $species = shift || die( "Need a species!" );
  my @databases =  @_;

  for my $database (@databases){
    unless( defined($self->{'_dbs'}->{$species}->{$database}) ) {
      my $dba = $reg->get_DBAdaptor( $species, $database );
      if (!defined($dba) || $database eq 'glovar'){
        $self->_get_databases_common( $species, $database );
      } else{
        $self->{'_dbs'}->{$species}->{$database} = $dba;
      }
    }
  }

  return $self->{'_dbs'}->{$species};
}


1;
