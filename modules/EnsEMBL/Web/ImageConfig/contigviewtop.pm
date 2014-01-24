package EnsEMBL::Web::ImageConfig::contigviewtop;

use strict;

sub _modify {
  my $self = shift;

  my $species      = $self->{'species'};
  my $species_defs = $self->species_defs;

# JIRA : ENSEMBL-2057 . Adding simple features to the contigview top as some features are better viewed when zoomed out

# create the simple submenu 
  $self->create_menus(qw(
			 simple
			 ));


# now need to call the corresponding function to add features of these type to the contigviewtop
  my @feature_calls = qw(add_simple_features);

  my $dbs_hash     = $self->databases;
  my ($check, $databases) = ($dbs_hash, $self->sd_call("core_like_databases"));
    
  foreach my $db (grep exists $check->{$_}, @{$databases || []}) {
      my $key = lc substr $db, 9;
      $self->$_($key, $check->{$db}{'tables'} || $check->{$db}, $species) for @feature_calls;
  }


} 

1;
