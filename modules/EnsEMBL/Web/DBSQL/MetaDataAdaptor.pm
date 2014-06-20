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

package EnsEMBL::Web::DBSQL::MetaDataAdaptor;

use strict;
use warnings;
no warnings 'uninitialized';

use Bio::EnsEMBL::DBSQL::DBConnection;
use Bio::EnsEMBL::Utils::MetaData::DBSQL::GenomeInfoAdaptor;

sub new {
  my ($class, $db_info) = @_;

  my $self = {
    NAME => $db_info->{NAME},
    HOST => $db_info->{HOST},
    PORT => $db_info->{PORT},
    USER => $db_info->{USER},
    PASS => $db_info->{PASS},
  };
  bless $self, $class;
  
  return $self;
}

sub db {
  my $self = shift;
  return unless $self->{'NAME'};

  $self->{'dbc'} ||= Bio::EnsEMBL::DBSQL::DBConnection->new(
      -USER   => $self->{USER},
      -PASS   => $self->{PASS},
      -PORT   => $self->{PORT},
      -HOST   => $self->{HOST},
      -DBNAME => $self->{NAME}
  );
  
  return $self->{'dbc'};
}

sub genome_info_adaptor {
  my $self = shift;
  return unless $self->db;

  $self->{genome_info_adaptor} ||= Bio::EnsEMBL::Utils::MetaData::DBSQL::GenomeInfoAdaptor->new(-DBC => $self->db);

  return $self->{genome_info_adaptor};
}

1;
