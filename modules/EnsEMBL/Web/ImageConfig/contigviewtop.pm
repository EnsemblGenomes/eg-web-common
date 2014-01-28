=head1 LICENSE

Copyright [2009-2014] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

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
