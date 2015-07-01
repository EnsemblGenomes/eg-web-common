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

package EnsEMBL::Web::DBSQL::DBConnection;


use strict;
use warnings;
no warnings "uninitialized";
use Carp;

use Bio::EnsEMBL::Registry;
use EnsEMBL::Web::RegObj;
use EnsEMBL::Web::Hub;
my $reg = "Bio::EnsEMBL::Registry";


sub get_DBAdaptor {
  my $self     = shift;
  my $database = shift || $self->error('FATAL', 'Need a DBAdaptor name');
     $database = 'SNP'           if $database eq 'snp';
     $database = 'otherfeatures' if $database eq 'est';
  my $species  = shift || $self->default_species;
  
  $self->{'_dbs'}{$species} ||= {}; 

  # if we have connected to the db before, return the adaptor from the cache
  return $self->{'_dbs'}{$species}{$database} if exists $self->{'_dbs'}{$species}{$database};

  # try to retrieve the DBAdaptor from the Registry
  my $dba = $reg->get_DBAdaptor($species, $database);
  # warn "$species - $database - $dba";

## EG MULTI
  my $hub = EnsEMBL::Web::Hub->new;
  
  if (! $dba ) {
    my $sg = $hub->species_defs->get_config($species, "SPECIES_DATASET");
    $dba = $reg->get_DBAdaptor($sg, $database) if $sg;
    if ($dba) {
      $dba->{_is_multispecies} = 1;
      $dba->{_species_id} = $hub->species_defs->get_config($species, "SPECIES_META_ID");
    }
  }
##

  # Funcgen Database Files Overwrite
  if ($database eq 'funcgen' && $self->{'species_defs'}->databases->{'DATABASE_FUNCGEN'}{'NAME'}) {
    my $file_path = join '/', $self->{'species_defs'}->DATAFILE_BASE_PATH, lc $species, $self->{'species_defs'}->ASSEMBLY_VERSION;
    $dba->get_ResultSetAdaptor->dbfile_data_root($file_path) if -e $file_path && -d $file_path;
  }  
  
  $self->{'_dbs'}{$species}{$database} = $dba;
  
  return $self->{'_dbs'}{$species}{$database};
}




1;
