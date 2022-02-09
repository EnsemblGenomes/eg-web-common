=head1 LICENSE

Copyright [2009-2022] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::DBSQL::MetaDataAdaptor;

use strict;
use warnings;
no warnings 'uninitialized';

use Bio::EnsEMBL::DBSQL::DBConnection;
use Bio::EnsEMBL::MetaData::DBSQL::MetaDataDBAdaptor;

sub new {
  my ($class, $hub) = @_;

  my $db = $hub->species_defs->multidb->{'DATABASE_METADATA'};

  my $self = {
    NAME => $db->{NAME},
    HOST => $db->{HOST},
    PORT => $db->{PORT},
    USER => $db->{USER},
    PASS => $db->{PASS},
    hub  => $hub,
  };

  return bless $self, $class;
}

sub mdba {
  my $self = shift;
  return unless $self->{'NAME'};

  $self->{'mdba'} ||= Bio::EnsEMBL::MetaData::DBSQL::MetaDataDBAdaptor->new(
    -USER   => $self->{USER},
    -PASS   => $self->{PASS},
    -PORT   => $self->{PORT},
    -HOST   => $self->{HOST},
    -DBNAME => $self->{NAME}
  );
  
  return $self->{'mdba'};
}

sub genome_info_adaptor {
  my $self = shift;
  return unless $self->mdba;
  
  unless ($self->{genome_info_adaptor}) {
    my $gdba    = $self->mdba->get_GenomeInfoAdaptor();
    my $release = $self->mdba->get_DataReleaseInfoAdaptor->fetch_by_ensembl_genomes_release($SiteDefs::SITE_RELEASE_VERSION);
    $gdba->data_release($release);
    $self->{genome_info_adaptor} = $gdba;
  }

  return $self->{genome_info_adaptor};
}

sub genome {
  my ($self, $species) = @_;
  $species ||= $self->{hub}->species;
  return $self->genome_info_adaptor->fetch_by_name($species);
}

sub all_genomes_by_division {
  my ($self, $division) = @_;
  return [] unless $self->genome_info_adaptor;
  $division ||= ( $self->{hub}->species_defs->ENSEMBL_SITETYPE =~ s/\s+//gr ); #/
  return $self->genome_info_adaptor->fetch_all_by_division($division);
}

1;
